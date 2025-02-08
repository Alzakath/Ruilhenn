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


function BindingsManager:Save()
    local bindings = {}
    for i = 1, GetNumBindings() do
        local command, key1, key2 = GetBinding(i)
        table.insert(bindings, { command = command, key1 = key1, key2 = key2 })
    end
    RuilhennDB.keyBindings = bindings
    ns.Log:Debug(L["KEY_BINDINGS_SAVED"])
end

function BindingsManager:Load()
    if RuilhennDB.keyBindings then
        for _, bind in ipairs(RuilhennDB.keyBindings) do
            SetBinding(bind.key1, bind.command)
            SetBinding(bind.key2, bind.command)
        end
        SaveBindings(GetCurrentBindingSet())
        ns.Log:Debug(L["KEY_BINDINGS_LOADED"])
    end
end

BindingsManager.subcommands = {
    ["load"] = function()
        ns.Log:Debug("BindingsManager:Load")
    end,
    ["save"] = function()
        ns.Log:Debug("BindingsManager:Save")
    end
}

Commands["bindings"] = function(subcommand)
    local func = BindingsManager.subcommands[subcommand]

    if type(func) ~= "function" then
        return
    end

    local success, err = pcall(func)
    if not success then
        ns.Log:Debug("Command execution error: " .. err)
    end
end