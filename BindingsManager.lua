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

local L = ns.L or {} -- fallback if localization table is not available

-- Ensure DB exists
RuilhennDB = RuilhennDB or {}

function BindingsManager:Save()
    -- Save current binding set id so we can restore to the same set later
    local bindingSet = GetCurrentBindingSet()
    local bindings = {}

    for i = 1, GetNumBindings() do
        local command, key1, key2 = GetBinding(i)
        -- Normalize empty-string keys to nil; only save entries that have a command and at least one key
        local normKey1 = (key1 and key1 ~= "") and key1 or nil
        local normKey2 = (key2 and key2 ~= "") and key2 or nil
        if command and command ~= "" and (normKey1 or normKey2) then
            table.insert(bindings, {
                command = command,
                key1 = (key1 and key1 ~= "") and key1 or nil,
                key2 = (key2 and key2 ~= "") and key2 or nil,
            })
        end
    end

    RuilhennDB.keyBindings = bindings
    RuilhennDB.bindingSet = bindingSet

    -- Use Message for user-visible messages; fall back to a plain string if localization is missing
    ns.Log:Message(L["KEY_BINDINGS_SAVED"] or "Key bindings saved.")
end

function BindingsManager:Load()
    if InCombatLockdown() then
        ns.Log:Error(L["ERR_IN_COMBAT"] or "Cannot restore key bindings in combat.")
        return
    end

    if not RuilhennDB or not RuilhennDB.keyBindings then
        ns.Log:Debug("BindingsManager:Load called but no saved bindings exist.")
        return
    end

    -- Apply saved bindings. Only set bindings if both key and command exist.
    for _, bind in ipairs(RuilhennDB.keyBindings) do
        if bind and bind.command then
            if bind.key1 then
                SetBinding(bind.key1, bind.command)
            end
            if bind.key2 then
                SetBinding(bind.key2, bind.command)
            end
        end
    end

    -- Restore to the saved binding set if available; otherwise save to current.
    local targetSet = RuilhennDB.bindingSet or GetCurrentBindingSet()
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