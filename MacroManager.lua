-- MacroManager.lua
local _, ns = ...
local MacroManager = ns.MacroManager
local Commands = ns.Commands

-- WoW API
local CreateMacro = CreateMacro
local EditMacro = EditMacro
local GetMacroInfo = GetMacroInfo
local GetSpellName = C_Spell.GetSpellName
local GetItemInfo = C_Item.GetItemInfo
local UnitClass = UnitClass

-- local variables
NUM_CHARACTER_MACROS = 18
FIRST_CHARACTER_MACRO_INDEX = 121

function MacroManager:ReplaceSpellIDs(macroBody)
    local expandedMacroBody = macroBody:gsub("%%spell:(%d+)%%", function(spellID)
        local spellName = GetSpellName(tonumber(spellID))
        return spellName or "UnknownSpell"
    end)

    expandedMacroBody = expandedMacroBody:gsub("%%item:(%d+)%%", function(itemID)
        local itemName = GetItemInfo(tonumber(itemID))
        return itemName or "UnknownItem"
    end)

    return expandedMacroBody
end

function MacroManager:EnsureMacroExists(macro)
    local localizedBody = self:ReplaceSpellIDs(macro.body)
    local macroIndex = self:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        CreateMacro(macro.name, macro.icon, localizedBody, true)
        ns.Log:Debug(ns.L["MACRO_CREATED"]:format(macro.name))
    else
        EditMacro(macroIndex, macro.name, macro.icon, localizedBody)
        ns.Log:Debug(ns.L["MACRO_UPDATED"]:format(macro.name))
    end
end

function MacroManager:FindCharacterMacro(macroName)
    for i = 1, NUM_CHARACTER_MACROS do
        local macroIndex = i + FIRST_CHARACTER_MACRO_INDEX - 1
        local name = GetMacroInfo(macroIndex)
        if name == macroName then
            return macroIndex
        end
    end
    return 0
end

function MacroManager:GetTemplates(playerClass)

    local templates = ns.MacroTemplates or {}
    
    return templates[playerClass] or nil
end

MacroManager.subcommands = {
    ["init"] = function()
        local _, playerClass = UnitClass("player")
        ns.Log:Message(ns.L["CLASS_DETECTED"]:format(playerClass))
    
        local macroGenerator =  MacroManager:GetTemplates(playerClass)
        if macroGenerator then
            local queue = ns.TaskQueue:New(5)
            local macros = macroGenerator()
            for _, macro in ipairs(macros) do
                queue:AddTask(function()
                    MacroManager:EnsureMacroExists(macro)
                end)
            end
            queue:Run()
        else
            ns.Log:Warning(ns.L["NO_MACROS_DEFINED"]:format(playerClass))
        end
    end
}

Commands["macro"] = function(subcommand)
    local func = MacroManager.subcommands[subcommand]

    if type(func) ~= "function" then
        return
    end

    local success, err = pcall(func)
    if not success then
        ns.Log:Debug("Command execution error: " .. err)
    end
end