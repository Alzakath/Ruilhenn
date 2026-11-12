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
local NUM_CHARACTER_MACROS = Constants.MacroConsts.MAX_CHARACTER_MACROS
local FIRST_CHARACTER_MACRO_INDEX = Constants.MacroConsts.MAX_ACCOUNT_MACROS + 1

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
    if InCombatLockdown() then
        ns.Log:Error(ns.L["ERR_IN_COMBAT"] or "Cannot manage macros in combat.")
        return
    end

    local localizedBody = self:ReplaceSpellIDs(macro.body)
    local macroIndex, freeSlot = self:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        if not freeSlot then
            ns.Log:Error((ns.L["MACRO_STORAGE_FULL"] or "Cannot create macro %s: character macro storage is full."):format(macro.name))
            return false
        end
        local ok, result = pcall(CreateMacro, macro.name, macro.icon, localizedBody, true)
        if not ok or type(result) ~= "number" or result < FIRST_CHARACTER_MACRO_INDEX or
            result >= FIRST_CHARACTER_MACRO_INDEX + NUM_CHARACTER_MACROS then
            ns.Log:Error((ns.L["MACRO_WRITE_FAILED"] or "Could not save macro %s."):format(macro.name))
            if not ok then ns.Log:Debug(tostring(result)) end
            return false
        end
        ns.Log:Debug(ns.L["MACRO_CREATED"]:format(macro.name))
    else
        local ok, result = pcall(EditMacro, macroIndex, macro.name, macro.icon, localizedBody)
        if not ok or result ~= macroIndex then
            ns.Log:Error((ns.L["MACRO_WRITE_FAILED"] or "Could not save macro %s."):format(macro.name))
            if not ok then ns.Log:Debug(tostring(result)) end
            return false
        end
        ns.Log:Debug(ns.L["MACRO_UPDATED"]:format(macro.name))
    end
    return true
end

function MacroManager:FindCharacterMacro(macroName)
    local freeSlot
    for i = 1, NUM_CHARACTER_MACROS do
        local macroIndex = i + FIRST_CHARACTER_MACRO_INDEX - 1
        local name = GetMacroInfo(macroIndex)
        if not name and not freeSlot then freeSlot = macroIndex end
        if name == macroName then
            return macroIndex
        end
    end
    return 0, freeSlot
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
