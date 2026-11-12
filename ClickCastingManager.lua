local _, ns = ...
local Manager = {}
ns.ClickCastingManager = Manager
local L = ns.L
local VERSION = 1

local function editorOpen()
    return ClickBindingFrame and type(ClickBindingFrame.IsShown) == "function" and ClickBindingFrame:IsShown()
end

local function fail(key, value)
    local text = L[key]
    ns.Log:Error(value ~= nil and text:format(tostring(value)) or text)
    return false
end

local function available(write)
    return type(C_ClickBindings) == "table" and type(C_ClickBindings.GetProfileInfo) == "function" and
        (not write or type(C_ClickBindings.SetProfileByInfo) == "function") and
        Enum and type(Enum.ClickBindingType) == "table" and type(Enum.ClickBindingInteraction) == "table" and
        C_SpecializationInfo and type(C_SpecializationInfo.GetSpecialization) == "function" and
        type(C_SpecializationInfo.GetSpecializationInfo) == "function"
end

local function context()
    local index = C_SpecializationInfo.GetSpecialization()
    if type(index) ~= "number" or index < 1 then return end
    local specID = index and C_SpecializationInfo.GetSpecializationInfo(index)
    local _, class = UnitClass("player")
    if type(specID) ~= "number" or specID <= 0 or not class then return end
    return class, specID
end

local function integer(value)
    return type(value) == "number" and value >= 0 and value < math.huge and value == math.floor(value)
end

local function key(row)
    return #row.button .. ":" .. row.button .. ":" .. row.modifiers
end

-- Only copy the documented native fields. Validate every record before writing.
local function copyProfile(profile)
    if type(profile) ~= "table" then return end
    local count, maximum = 0, 0
    for index in pairs(profile) do
        if not integer(index) or index < 1 then return end
        count, maximum = count + 1, math.max(maximum, index)
    end
    if count ~= maximum then return end
    local types, interactions = Enum.ClickBindingType, Enum.ClickBindingInteraction
    local result, seen = {}, {}
    for i = 1, count do
        local row = profile[i]
        if type(row) ~= "table" or not integer(row.actionID) or not integer(row.modifiers) or
            type(row.button) ~= "string" or row.button == "" then return end
        local kind = row.type
        if kind ~= types.None and kind ~= types.Spell and kind ~= types.Macro and
            kind ~= types.Interaction and kind ~= types.PetAction then return end
        if kind ~= types.None and row.actionID == 0 then return end
        if kind == types.Interaction and row.actionID ~= interactions.Target and
            row.actionID ~= interactions.OpenContextMenu then return end
        local identity = key(row)
        if seen[identity] then return end
        seen[identity] = true
        result[i] = { type = kind, actionID = row.actionID, button = row.button, modifiers = row.modifiers }
    end
    return result
end

local function readProfile()
    local ok, value = pcall(C_ClickBindings.GetProfileInfo)
    if not ok then ns.Log:Debug(tostring(value)); return end
    return copyProfile(value)
end

local function macroInfo(index)
    local ok, name, _, body = pcall(GetMacroInfo, index)
    if ok and type(name) == "string" and type(body) == "string" then return name, body end
end

local function scope(index)
    return index > Constants.MacroConsts.MAX_ACCOUNT_MACROS and "character" or "account"
end

local function resolveMacro(identity)
    if type(identity) ~= "table" or type(identity.name) ~= "string" or
        type(identity.body) ~= "string" or
        (identity.scope ~= "account" and identity.scope ~= "character") then return end
    local offset = identity.scope == "character" and Constants.MacroConsts.MAX_ACCOUNT_MACROS or 0
    local count = identity.scope == "character" and Constants.MacroConsts.MAX_CHARACTER_MACROS or
        Constants.MacroConsts.MAX_ACCOUNT_MACROS
    local candidates, exact = {}, {}
    for index = offset + 1, offset + count do
        local name, body = macroInfo(index)
        if name == identity.name then
            candidates[#candidates + 1] = index
            if body == identity.body then exact[#exact + 1] = index end
        end
    end
    if #candidates == 1 then return candidates[1] end
    if #exact == 1 then return exact[1] end
end

local function sameProfile(actual, desired)
    if not actual or #actual ~= #desired then return false end
    local wanted = {}
    for _, row in ipairs(desired) do wanted[key(row)] = row end
    for _, row in ipairs(actual) do
        local match = wanted[key(row)]
        if not match or row.type ~= match.type or row.actionID ~= match.actionID then return false end
    end
    return true
end

function Manager:Save()
    if InCombatLockdown() then return fail("CLICKS_COMBAT") end
    if editorOpen() then return fail("CLICKS_EDITOR_OPEN") end
    if not available(false) then return fail("CLICKS_API_UNAVAILABLE") end
    local class, specID = context()
    if not class then return fail("CLICKS_NO_SPEC") end
    local rows = readProfile()
    if not rows then return fail("CLICKS_READ_FAILED") end
    for _, row in ipairs(rows) do
        if row.type == Enum.ClickBindingType.Macro then
            local name, body = macroInfo(row.actionID)
            if not name then return fail("CLICKS_MACRO_UNRESOLVED", row.actionID) end
            row.macro = { name = name, body = body, scope = scope(row.actionID) }
        end
    end
    if RuilhennDB.clickCasting ~= nil and type(RuilhennDB.clickCasting) ~= "table" then return fail("CLICKS_INVALID") end
    if RuilhennDB.clickCasting and RuilhennDB.clickCasting[class] ~= nil and
        type(RuilhennDB.clickCasting[class]) ~= "table" then return fail("CLICKS_INVALID") end
    RuilhennDB.clickCasting = RuilhennDB.clickCasting or {}
    RuilhennDB.clickCasting[class] = RuilhennDB.clickCasting[class] or {}
    RuilhennDB.clickCasting[class][specID] = { version = VERSION, bindings = rows }
    ns.Log:Message(L.CLICKS_SAVED:format(#rows))
    return true
end

function Manager:Load()
    if InCombatLockdown() then return fail("CLICKS_COMBAT") end
    if editorOpen() then return fail("CLICKS_EDITOR_OPEN") end
    if not available(true) then return fail("CLICKS_API_UNAVAILABLE") end
    local class, specID = context()
    if not class then return fail("CLICKS_NO_SPEC") end
    local root = RuilhennDB.clickCasting
    if root ~= nil and type(root) ~= "table" then return fail("CLICKS_INVALID") end
    local byClass = root and root[class]
    if byClass ~= nil and type(byClass) ~= "table" then return fail("CLICKS_INVALID") end
    local saved = byClass and byClass[specID]
    if not saved then return fail("CLICKS_NO_PROFILE") end
    if type(saved) ~= "table" or saved.version ~= VERSION then return fail("CLICKS_INVALID") end
    local rows = copyProfile(saved.bindings)
    if not rows then return fail("CLICKS_INVALID") end
    local applicable, skipped = {}, {}
    for i, row in ipairs(rows) do
        local missingSpell = false
        if row.type == Enum.ClickBindingType.Spell then
            if not C_SpellBook or type(C_SpellBook.IsSpellInSpellBook) ~= "function" or
                not Enum.SpellBookSpellBank then return fail("CLICKS_API_UNAVAILABLE") end
            local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, row.actionID,
                Enum.SpellBookSpellBank.Player, false)
            if not ok or type(known) ~= "boolean" then return fail("CLICKS_READ_FAILED") end
            missingSpell = not known
        end
        if missingSpell then
            skipped[#skipped + 1] = tostring(row.actionID)
        elseif row.type == Enum.ClickBindingType.Macro then
            local identity = saved.bindings[i].macro
            local index = resolveMacro(identity)
            if not index then
                return fail("CLICKS_MACRO_UNRESOLVED", type(identity) == "table" and identity.name or row.actionID)
            end
            row.actionID = index
        elseif row.type == Enum.ClickBindingType.Spell or row.type == Enum.ClickBindingType.PetAction then
            if type(C_ClickBindings.CanSpellBeClickBound) ~= "function" then return fail("CLICKS_API_UNAVAILABLE") end
            local ok, allowed = pcall(C_ClickBindings.CanSpellBeClickBound, row.actionID)
            if not ok or not allowed then return fail("CLICKS_ACTION_UNAVAILABLE", row.actionID) end
        end
        if not missingSpell then applicable[#applicable + 1] = row end
    end
    rows = applicable
    if #skipped > 0 then
        ns.Log:Warning(L.CLICKS_SKIPPED_SPELLS:format(#skipped, table.concat(skipped, ", ")))
    end
    -- The setter declares no return. A successful pcall alone is not success.
    local desired = copyProfile(rows)
    local before = readProfile()
    if not before then return fail("CLICKS_READ_FAILED") end
    local diagnostic = { class = class, specID = specID, desired = desired, before = before }
    RuilhennDB.clickCastingRestoreDiagnostic = diagnostic
    local ok, errorText = pcall(C_ClickBindings.SetProfileByInfo, rows)
    diagnostic.actual = readProfile()
    if not ok then diagnostic.writeError = tostring(errorText); return fail("CLICKS_WRITE_ERROR", errorText) end
    if not sameProfile(diagnostic.actual, desired) then return fail("CLICKS_NOT_APPLIED") end
    ns.Log:Message(L.CLICKS_LOADED:format(#rows))
    return true
end

function Manager:Status()
    if not available(false) then return fail("CLICKS_API_UNAVAILABLE") end
    local diagnostic = RuilhennDB.clickCastingRestoreDiagnostic
    if not diagnostic then return fail("CLICKS_NO_DIAGNOSTIC") end
    local class, specID = context()
    if class ~= diagnostic.class or specID ~= diagnostic.specID then return fail("CLICKS_DIAGNOSTIC_SPEC") end
    local actual = readProfile()
    if not actual then return fail("CLICKS_READ_FAILED") end
    diagnostic.actual = actual
    if sameProfile(actual, diagnostic.desired) then
        ns.Log:Message(L.CLICKS_STATUS_MATCH:format(#actual))
        return true
    end
    local unchanged = sameProfile(actual, diagnostic.before)
    ns.Log:Message(L.CLICKS_STATUS:format(#diagnostic.desired, #actual,
        unchanged and L.CLICKS_STATUS_UNCHANGED or L.CLICKS_STATUS_CHANGED))
    local wanted, current = {}, {}
    for _, row in ipairs(diagnostic.desired) do wanted[key(row)] = row end
    for _, row in ipairs(actual) do current[key(row)] = row end
    local function show(expected, observed)
        local row = expected or observed
        ns.Log:Message(L.CLICKS_STATUS_ROW:format(row.button, tostring(row.modifiers),
            expected and tostring(expected.type) or "-", expected and tostring(expected.actionID) or "-",
            observed and tostring(observed.type) or "-", observed and tostring(observed.actionID) or "-"))
    end
    for _, row in ipairs(diagnostic.desired) do
        local observed = current[key(row)]
        if not observed or row.type ~= observed.type or row.actionID ~= observed.actionID then show(row, observed) end
    end
    for _, row in ipairs(actual) do if not wanted[key(row)] then show(nil, row) end end
    return false
end

ns.Commands.clicks = function(subcommand)
    local action = subcommand == "save" and Manager.Save or subcommand == "load" and Manager.Load or
        subcommand == "status" and Manager.Status
    if not action then ns.Log:Message(L.CLICKS_USAGE); return end
    local ok, err = pcall(action, Manager)
    if not ok then fail("CLICKS_WRITE_ERROR", err) end
end
