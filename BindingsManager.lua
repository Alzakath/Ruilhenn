-- BindingsManager.lua
local _, ns = ...
local BindingsManager = ns.BindingsManager
local Commands = ns.Commands

-- WoW API
local GetNumBindings = GetNumBindings
local GetBinding = GetBinding
local SetBinding = SetBinding
local SaveBindings = SaveBindings
local GetCurrentBindingSet = GetCurrentBindingSet
local LoadBindings = LoadBindings
local C_KeyBindings = C_KeyBindings

local L = ns.L or {} -- fallback if localization table is not available
local BINDINGS_VERSION = 1
local ACCOUNT_BINDINGS, CHARACTER_BINDINGS = 1, 2

-- Ensure DB exists
RuilhennDB = RuilhennDB or {}

function BindingsManager:Save()
    -- Save current binding set id so we can restore to the same set later
    local bindingSet = GetCurrentBindingSet()
    local bindings = {}

    for i = 1, GetNumBindings() do
        local command, _, key1, key2 = GetBinding(i)
        -- Normalize empty-string keys to nil; only save entries that have a command and at least one key
        local normKey1 = (key1 and key1 ~= "") and key1 or nil
        local normKey2 = (key2 and key2 ~= "") and key2 or nil
        if command and command ~= "" and (normKey1 or normKey2) then
            table.insert(bindings, {
                command = command,
                key1 = normKey1,
                key2 = normKey2,
            })
        end
    end

    RuilhennDB.keyBindings = bindings
    RuilhennDB.bindingSet = bindingSet
    RuilhennDB.keyBindingsVersion = BINDINGS_VERSION
    if ns.TemplateStore then ns.TemplateStore:Record("bindings") end

    -- Use Message for user-visible messages; fall back to a plain string if localization is missing
    ns.Log:Message(L["KEY_BINDINGS_SAVED"] or "Key bindings saved.")
end

local function bindingEditorOpen()
    -- Retail and older clients expose the native editor through one of these
    -- frames. Ignore stale child visibility when its parent is closed.
    for _, frame in ipairs({ KeyBindingFrame, QuickKeybindFrame }) do
        if frame and type(frame.IsShown) == "function" then
            local ok, shown = pcall(frame.IsShown, frame)
            local visibleOK, visible = pcall(frame.IsVisible or frame.IsShown, frame)
            if ok and shown and (not visibleOK or visible) then return true end
        end
    end
    return false
end

local function operationBlockReason()
    if InCombatLockdown() then return L.UI_BINDING_COMBAT end
    if bindingEditorOpen() then return L.UI_BINDING_EDITOR_OPEN end
    if type(GetCurrentBindingSet) ~= "function" or type(GetNumBindings) ~= "function" or
        type(GetBinding) ~= "function" or type(SetBinding) ~= "function" or
        type(SaveBindings) ~= "function" or type(LoadBindings) ~= "function" then
        return L.UI_BINDING_API_UNAVAILABLE
    end
    local ok, set = pcall(GetCurrentBindingSet)
    if not ok or (set ~= ACCOUNT_BINDINGS and set ~= CHARACTER_BINDINGS) then
        return L.UI_BINDING_API_UNAVAILABLE
    end
end

function BindingsManager:OperationBlockReason()
    return operationBlockReason()
end

local function captureBindings(contextAware)
    local ok, count = pcall(GetNumBindings)
    if not ok then return nil, L.UI_BINDING_READ_FAILED end
    if type(count) ~= "number" or count < 0 then
        return nil, L.UI_BINDING_READ_FAILED
    end
    local bindings, seen = {}, {}
    if contextAware and (type(C_KeyBindings) ~= "table" or
        type(C_KeyBindings.GetBindingContextForAction) ~= "function") then
        return nil, L.UI_BINDING_API_UNAVAILABLE
    end
    for index = 1, count do
        local readOK, values = pcall(function()
            local packed = { n = 0 }
            local function pack(...) packed.n = select("#", ...); for i = 1, packed.n do packed[i] = select(i, ...) end end
            pack(GetBinding(index, true))
            return packed
        end)
        if not readOK then return nil, L.UI_BINDING_READ_FAILED end
        if type(values[1]) ~= "string" then
            return nil, L.UI_BINDING_READ_FAILED
        end
        local command = values[1]
        local context
        if contextAware then
            local contextOK
            contextOK, context = pcall(C_KeyBindings.GetBindingContextForAction, command)
            if not contextOK then
                return nil, L.UI_BINDING_READ_FAILED
            end
        end
        for keyIndex = 3, values.n do
            local key = values[keyIndex]
            if key and key ~= "" then
                local contextKey = contextAware and (context == nil and "<nil>" or tostring(context)) or "<flat>"
                local identity = contextKey .. "\001" .. key
                if seen[identity] and seen[identity] ~= command then
                    return nil, L.UI_BINDING_READ_FAILED
                end
                if not seen[identity] then
                    seen[identity] = command
                    local binding = { key = key, command = command }
                    if contextAware then binding.context = context end
                    bindings[#bindings + 1] = binding
                end
            end
        end
    end
    table.sort(bindings, function(a, b)
        local aContext = contextAware and (a.context == nil and "<nil>" or tostring(a.context)) or "<flat>"
        local bContext = contextAware and (b.context == nil and "<nil>" or tostring(b.context)) or "<flat>"
        if aContext ~= bContext then return aContext < bContext end
        if a.key ~= b.key then return a.key < b.key end
        return a.command < b.command
    end)
    return { bindings = bindings, contextAware = contextAware == true }
end

local function bindingFingerprint(snapshot)
    local parts = {}
    for _, item in ipairs(snapshot.bindings) do
        if snapshot.contextAware then
            local context = item.context == nil and "<nil>" or tostring(item.context)
            parts[#parts + 1] = context .. "\001" .. item.key .. "\001" .. item.command
        else
            parts[#parts + 1] = item.key .. "\001" .. item.command
        end
    end
    return table.concat(parts, "\002")
end

local function loadSet(set)
    local ok = pcall(LoadBindings, set)
    return ok
end

local function applyExact(snapshot, contextAware)
    contextAware = contextAware == true or snapshot.contextAware == true
    local current, err = captureBindings(contextAware)
    if not current then return false, err end
    for _, item in ipairs(current.bindings) do
        local ok, result
        if contextAware then ok, result = pcall(SetBinding, item.key, nil, item.context)
        else ok, result = pcall(SetBinding, item.key) end
        if not ok or not result then return false, L.UI_BINDING_WRITE_FAILED end
    end
    for _, item in ipairs(snapshot.bindings) do
        local ok, result
        if contextAware then ok, result = pcall(SetBinding, item.key, item.command, item.context)
        else ok, result = pcall(SetBinding, item.key, item.command) end
        if not ok or not result then return false, L.UI_BINDING_WRITE_FAILED end
    end
    local verified, verifyError = captureBindings(contextAware)
    if not verified or bindingFingerprint(verified) ~= bindingFingerprint(snapshot) then
        return false, verifyError or L.UI_BINDING_VERIFY_FAILED
    end
    return true
end

local function restoreLiveState(bindingSet, snapshot)
    return loadSet(bindingSet) and applyExact(snapshot)
end

-- Read a persisted binding set while restoring the exact prior live map. This
-- never calls SaveBindings, so a preview cannot write either saved set.
function BindingsManager:ReadBindingSetPreservingLiveState(bindingSet)
    local block = operationBlockReason()
    if block then return nil, block end
    if bindingSet ~= ACCOUNT_BINDINGS and bindingSet ~= CHARACTER_BINDINGS then
        return nil, L.UI_BINDING_API_UNAVAILABLE
    end
    local originalSet = GetCurrentBindingSet()
    local original, err = captureBindings(true)
    if not original then return nil, err end
    if not loadSet(bindingSet) then
        local restored = loadSet(originalSet)
        if restored then restored = applyExact(original, true) end
        if not restored then
            return nil, L.UI_BINDING_STATE_RESTORE_FAILED
        end
        return nil, L.UI_BINDING_READ_FAILED
    end
    local requested, requestedError = captureBindings(true)

    local restored = loadSet(originalSet)
    local restoreError
    if restored then restored, restoreError = applyExact(original, true) end
    local modeOK, mode = pcall(GetCurrentBindingSet)
    if not restored or not modeOK or mode ~= originalSet then
        return nil, L.UI_BINDING_STATE_RESTORE_FAILED .. (restoreError and (" " .. restoreError) or "")
    end
    if not requested then
        return nil, requestedError
    end
    return requested, bindingFingerprint(requested)
end

local function profileIsValid(profile)
    if not profile or type(profile.bindings) ~= "table" then return false end
    if profile.version ~= BINDINGS_VERSION then
        ns.Log:Error(L["KEY_BINDINGS_BACKUP_OUTDATED"] or "Incompatible binding backup.")
        return false
    end
    for _, bind in ipairs(profile.bindings) do
        if type(bind) ~= "table" or type(bind.command) ~= "string" or
            (bind.key1 ~= nil and type(bind.key1) ~= "string") or
            (bind.key2 ~= nil and type(bind.key2) ~= "string") then
            ns.Log:Error(L.UI_BINDING_READ_FAILED)
            return false
        end
    end
    return true
end

function BindingsManager:SaveForBrowser()
    local block = operationBlockReason()
    if block then ns.Log:Warning(block); return false end
    return self:Save()
end

-- Browser-only import path. Source bindingSet remains provenance; the actual
-- destination is always the character's saved set, and only set 2 is saved.
function BindingsManager:LoadForCharacter(profile)
    local block = operationBlockReason()
    if block then ns.Log:Warning(block); return false end
    if not profileIsValid(profile) then return false end

    local originalSet = GetCurrentBindingSet()
    local original, err = captureBindings()
    if not original then ns.Log:Error(err); return false end
    if not loadSet(CHARACTER_BINDINGS) then
        local restored = restoreLiveState(originalSet, original)
        ns.Log:Error(L.UI_BINDING_READ_FAILED .. " " ..
            (restored and L.UI_BINDING_SESSION_RESTORED or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    local characterBase, baseError = captureBindings()
    if not characterBase then
        local restored = restoreLiveState(originalSet, original)
        ns.Log:Error((baseError or L.UI_BINDING_READ_FAILED) .. " " ..
            (restored and L.UI_BINDING_SESSION_RESTORED or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end

    local expected = { bindings = {} }
    local byKey = {}
    for _, item in ipairs(characterBase.bindings) do byKey[item.key] = item.command end
    for _, bind in ipairs(profile.bindings) do
        if bind.key1 and bind.key1 ~= "" then byKey[bind.key1] = bind.command end
        if bind.key2 and bind.key2 ~= "" then byKey[bind.key2] = bind.command end
    end
    for key, command in pairs(byKey) do expected.bindings[#expected.bindings + 1] = { key = key, command = command } end
    table.sort(expected.bindings, function(a, b) return a.key < b.key end)

    local changed = false
    for _, bind in ipairs(profile.bindings) do
        for _, key in pairs({ bind.key1, bind.key2 }) do
            if key and key ~= "" then
                local ok, result = pcall(SetBinding, key, bind.command)
                if not ok or not result then changed = true; break end
            end
        end
        if changed then break end
    end
    local actual, actualError = captureBindings()
    if changed or not actual or bindingFingerprint(actual) ~= bindingFingerprint(expected) then
        local restoreOK = restoreLiveState(originalSet, original)
        ns.Log:Error((changed and L.UI_BINDING_WRITE_FAILED or actualError or L.UI_BINDING_VERIFY_FAILED) ..
            (restoreOK and " " .. L.UI_BINDING_SESSION_RESTORED or " " .. L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end

    local saveOK = pcall(SaveBindings, CHARACTER_BINDINGS)
    local modeOK, mode = pcall(GetCurrentBindingSet)
    if not saveOK or not modeOK or mode ~= CHARACTER_BINDINGS then
        local rolledBack
        if modeOK and mode == CHARACTER_BINDINGS then
            rolledBack = loadSet(CHARACTER_BINDINGS) and applyExact(characterBase) and
                pcall(SaveBindings, CHARACTER_BINDINGS)
        else
            rolledBack = restoreLiveState(originalSet, original)
        end
        ns.Log:Error(L.UI_BINDING_SAVE_FAILED .. " " ..
            (rolledBack and L.UI_BINDING_CHARACTER_ROLLED_BACK or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    if not loadSet(CHARACTER_BINDINGS) then
        ns.Log:Error(L.UI_BINDING_SAVE_FAILED .. " " .. L.UI_BINDING_SESSION_UNCERTAIN)
        return false
    end
    actual, actualError = captureBindings()
    if not actual or bindingFingerprint(actual) ~= bindingFingerprint(expected) then
        local rollback = loadSet(CHARACTER_BINDINGS) and applyExact(characterBase)
        local rollbackSaved = rollback and pcall(SaveBindings, CHARACTER_BINDINGS)
        ns.Log:Error((actualError or L.UI_BINDING_VERIFY_FAILED) .. " " ..
            (rollbackSaved and L.UI_BINDING_CHARACTER_ROLLED_BACK or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    ns.Log:Message(L.UI_BINDING_CHARACTER_IMPORTED)
    return true
end

function BindingsManager:CopyAccountBindings(expectedFingerprint)
    local block = operationBlockReason()
    if block then ns.Log:Warning(block); return false end
    local account, fingerprint = self:ReadBindingSetPreservingLiveState(ACCOUNT_BINDINGS)
    if not account then ns.Log:Error(fingerprint); return false end
    if expectedFingerprint and fingerprint ~= expectedFingerprint then
        ns.Log:Warning(L.UI_BINDING_BASELINE_STALE); return false
    end

    local originalSet = GetCurrentBindingSet()
    local originalLive, err = captureBindings(true)
    if not originalLive then ns.Log:Error(err); return false end
    if not loadSet(CHARACTER_BINDINGS) then
        local restored = restoreLiveState(originalSet, originalLive)
        ns.Log:Error(L.UI_BINDING_READ_FAILED .. " " ..
            (restored and L.UI_BINDING_SESSION_RESTORED or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    local oldCharacter, charError = captureBindings(true)
    if not oldCharacter then
        local restored = restoreLiveState(originalSet, originalLive)
        ns.Log:Error((charError or L.UI_BINDING_READ_FAILED) .. " " ..
            (restored and L.UI_BINDING_SESSION_RESTORED or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    local applied, applyError = applyExact(account, true)
    if not applied then
        local restored = restoreLiveState(originalSet, originalLive)
        ns.Log:Error(applyError .. (restored and " " .. L.UI_BINDING_SESSION_RESTORED or
            " " .. L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end

    local saved = pcall(SaveBindings, CHARACTER_BINDINGS)
    local modeOK, mode = pcall(GetCurrentBindingSet)
    if not saved or not modeOK or mode ~= CHARACTER_BINDINGS then
        local rolledBack
        if modeOK and mode == CHARACTER_BINDINGS then
            rolledBack = loadSet(CHARACTER_BINDINGS) and applyExact(oldCharacter, true) and
                pcall(SaveBindings, CHARACTER_BINDINGS)
        else
            rolledBack = restoreLiveState(originalSet, originalLive)
        end
        ns.Log:Error(L.UI_BINDING_SAVE_FAILED .. " " ..
            (rolledBack and L.UI_BINDING_CHARACTER_ROLLED_BACK or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    if not loadSet(CHARACTER_BINDINGS) then
        ns.Log:Error(L.UI_BINDING_SAVE_FAILED .. " " .. L.UI_BINDING_SESSION_UNCERTAIN)
        return false
    end
    local actual, verifyError = captureBindings(true)
    if not actual or bindingFingerprint(actual) ~= bindingFingerprint(account) then
        local rollback = loadSet(CHARACTER_BINDINGS) and applyExact(oldCharacter, true)
        local rollbackSaved = rollback and pcall(SaveBindings, CHARACTER_BINDINGS)
        ns.Log:Error((verifyError or L.UI_BINDING_VERIFY_FAILED) .. " " ..
            (rollbackSaved and L.UI_BINDING_CHARACTER_ROLLED_BACK or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end

    local savedAccount, accountFingerprint = self:ReadBindingSetPreservingLiveState(ACCOUNT_BINDINGS)
    if not savedAccount or accountFingerprint ~= fingerprint then
        local rollback = loadSet(CHARACTER_BINDINGS) and applyExact(oldCharacter, true)
        local rollbackSaved = rollback and pcall(SaveBindings, CHARACTER_BINDINGS)
        if rollbackSaved then loadSet(CHARACTER_BINDINGS) end
        ns.Log:Error(L.UI_BINDING_ACCOUNT_VERIFY_FAILED .. " " ..
            (rollbackSaved and L.UI_BINDING_CHARACTER_ROLLED_BACK or L.UI_BINDING_SESSION_UNCERTAIN))
        return false
    end
    ns.Log:Message(L.UI_BINDING_ACCOUNT_COPIED:format(#account.bindings))
    return true
end

function BindingsManager:Load(profile, destinationSet)
    if InCombatLockdown() then
        ns.Log:Error(L["ERR_IN_COMBAT"] or "Cannot restore key bindings in combat.")
        return
    end

    profile = profile or { bindings = RuilhennDB.keyBindings,
        version = RuilhennDB.keyBindingsVersion, bindingSet = RuilhennDB.bindingSet }
    if destinationSet == CHARACTER_BINDINGS then return self:LoadForCharacter(profile) end
    if not profile.bindings then
        ns.Log:Debug("BindingsManager:Load called but no saved bindings exist.")
        return
    end

    -- Older backups stored the category as a key and lost the second key.
    -- They cannot be repaired reliably without a fresh capture.
    if profile.version ~= BINDINGS_VERSION then
        ns.Log:Error(L["KEY_BINDINGS_BACKUP_OUTDATED"] or "This key binding backup is incompatible. Set up your desired bindings, then run /ruil bindings save to replace it before loading.")
        return
    end

    -- Apply saved bindings. Only set bindings if both key and command exist.
    local failed = false
    for _, bind in ipairs(profile.bindings) do
        if bind and bind.command then
            if bind.key1 and not SetBinding(bind.key1, bind.command) then
                failed = true
                ns.Log:Error((L["KEY_BINDING_FAILED"] or "Could not bind %s to %s."):format(bind.key1, bind.command))
            end
            if bind.key2 and not SetBinding(bind.key2, bind.command) then
                failed = true
                ns.Log:Error((L["KEY_BINDING_FAILED"] or "Could not bind %s to %s."):format(bind.key2, bind.command))
            end
        end
    end

    if failed then
        ns.Log:Error(L["KEY_BINDINGS_LOAD_INCOMPLETE"] or "Key binding restore was incomplete. Some bindings may have changed for this session; the result was not saved.")
        return
    end

    -- Restore to the saved binding set if available; otherwise save to current.
    local targetSet = profile.bindingSet or GetCurrentBindingSet()
    SaveBindings(targetSet)

    ns.Log:Message(L["KEY_BINDINGS_LOADED"] or "Key bindings loaded.")
end

-- Subcommands should actually call the methods above
BindingsManager.subcommands = {
    ["load"] = function()
        BindingsManager:Load()
    end,
    ["save"] = function()
        BindingsManager:Save()
    end
}

Commands["bindings"] = function(subcommand)
    local func = BindingsManager.subcommands[subcommand]

    if type(func) ~= "function" then
        ns.Log:Debug("bindings: unknown subcommand " .. tostring(subcommand))
        return
    end

    local success, err = pcall(func)
    if not success then
        ns.Log:Debug("Command execution error: " .. tostring(err))
    end
end
