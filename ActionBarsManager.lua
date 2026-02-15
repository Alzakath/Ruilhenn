-- ActionBarsManager.lua
local _, ns = ...
local ActionBarsManager = ns.ActionBarsManager
local Commands = ns.Commands

-- WoW API
local UnitClass = UnitClass
local GetMacroInfo = GetMacroInfo
local GetActionInfo = GetActionInfo
local PlaceAction = PlaceAction
local ClearCursor = ClearCursor
local GetSpellInfo = C_Spell.GetSpellInfo
local PickupSpell = C_Spell.PickupSpell
local PickupItem = PickupItem
local PickupMacro = PickupMacro
local PickupAction = PickupAction
local GetItemInfo = C_Item.GetItemInfo
local GetSpecialization = GetSpecialization
local GetActionText = GetActionText

local GetMountInfoByID = C_MountJournal.GetMountInfoByID
local GetMountIDs = C_MountJournal.GetMountIDs
local PickupMount = C_MountJournal.Pickup

ActionBarsManager.ACTION_BAR_SLOTS = {
    [1] = {start = 1, ["end"] = 12}, -- ActionBar page 1: slots 1 to 12
    [2] = {start = 13, ["end"] = 24}, -- ActionBar page 2: slots 13 to 24
    [3] = {start = 25, ["end"] = 36}, -- ActionBar page 3 (Right ActionBar): slots 25 to 36
    [4] = {start = 37, ["end"] = 48}, -- ActionBar page 4 (Right ActionBar 2): slots 37 to 48
    [5] = {start = 49, ["end"] = 60}, -- ActionBar page 5 (Bottom Right ActionBar): slots 49 to 60
    [6] = {start = 61, ["end"] = 72}, -- ActionBar page 6 (Bottom Left ActionBar): slots 61 to 72
    [7] = {start = 145, ["end"] = 156}, -- ActionBar page 7: slots 145 to 156
    [8] = {start = 157, ["end"] = 168}, -- ActionBar page 8: slots 157 to 168
    [9] = {start = 169, ["end"] = 180}, -- ActionBar page 9: slots 169 to 180
    [10] = {start = 73, ["end"] = 84}, -- ActionBar page 1 Cat Form: slots 73 to 84
    [11] = {start = 85, ["end"] = 96}, -- ActionBar page 1 Prowl: slots 85 to 96
    [12] = {start = 97, ["end"] = 108}, -- ActionBar page 1 Bear Form: slots 97 to 108
    [13] = {start = 109, ["end"] = 120}, -- ActionBar page 1 Moonkin Form: slots 109 to 120
    [14] = {start = 121, ["end"] = 132}, -- ActionBar page 1 Possess: slots 121-132
    -- 133 to 144 ??
}

ActionBarsManager.MANAGED_BARS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}

function ActionBarsManager:PickupActionSpell(actionId)
    -- Handle spell placement
    local spellInfo = GetSpellInfo(actionId)
    if spellInfo then
        PickupSpell(actionId)
        return true, spellInfo.name or ""
    else
        ns.Log:Error(ns.L["SPELL_NOT_FOUND"]:format(actionId))
    end
    return false, ""
end

function ActionBarsManager:PickupActionItem(actionId)
    -- Handle item placement
    local itemInfo = GetItemInfo(actionId)
    if itemInfo then
        PickupItem(actionId)
        return true, itemInfo[1] or ""
    else
        ns.Log:Error(ns.L["ITEM_NOT_FOUND"]:format(actionId))
    end
    return false, ""
end

function ActionBarsManager:PickupActionMacro(actionId)
    -- Handle macro placement
    local macroInfo = GetMacroInfo(actionId)
    if macroInfo then
        PickupMacro(actionId)
        return true, macroInfo[0] or ""
    else
        ns.Log:Error(ns.L["MACRO_NOT_FOUND"]:format(actionId))
    end
    return false, ""
end

function ActionBarsManager:PickupActionMount(actionId)
    -- Handle mount placement
    ns.Log:Warning(ns.L["MOUNT_CANNOT_BE_PLACED"])
    return true, ""
end

function ActionBarsManager:PlaceActionSafely(slot, actionId, actionType)
    if not slot or slot < 1 or slot > 180 then
        ns.Log:Error(ns.L["INVALID_ACTION_SLOT"]:format(slot or "nil"))
        return false
    end

    -- Clear the cursor before starting
    ClearCursor()

    local success = false
    local actionName = ""

    -- ns.Log:Debug(("PlaceActionSafely => slot: %s, actionId: %s, actionType: %s"):format(slot, actionId, actionType))
    
    if actionType == "spell" then

        success, actionName = self:PickupActionSpell(actionId)

    elseif actionType == "item" then

        success, actionName = self:PickupActionItem(actionId)

        
    elseif actionType == "macro" then

        success, actionName = self:PickupActionMacro(actionId)
    elseif actionType == "summonmount" then

        success, actionName = self:PickupActionMount(actionId)

    else
        ns.Log:Error(ns.L["INVALID_ACTION_TYPE"]:format(actionType))
        return false
    end

    if success then
        -- Place the action
        PlaceAction(slot)
        -- Verify placement
        local placedType = GetActionInfo(slot)
        if placedType == actionType then
            return true
        else
            ns.Log:Error(ns.L["ACTION_PLACED_FAILED"]:format(actionType, actionName, actionId, slot))
        end
    end

    -- Clear cursor if placement failed
    ClearCursor()
    return false
end

function ActionBarsManager:GetMacroInfoFromAction(slot)
    local macroInfo = GetActionInfo(slot)
    local macroName = GetActionText(slot)
    ns.Log:Debug(("GetMacroInfoFromAction for slot: %s => macroInfo: %s, macroName: %s"):format(slot, ns.Utils:DumpTable(macroInfo), macroName or ""))
    return GetMacroInfo(macroName), macroName
end

function ActionBarsManager:GetActionBarInfo(slot)
    local type, id, subType = GetActionInfo(slot)
    -- properly action infos for macros, mounts and critters
    -- if type then
    --     ns.Log:Debug(("GetActionBarInfo => type: %s, id: %s, subType: %s"):format(type or "", id or "", subType or ""))
    -- end
    if type == "macro" then
        local macroInfo, macroName = self:GetMacroInfoFromAction(slot)
        if macroInfo then
            return {type = "macro", id = macroName, subType = subType}
        else
            ns.Log:Error(ns.L["MACRO_NOT_FOUND"]:format(macroName or ""))
            return {}
        end
    end
    return {type = type, id = id, subType = subType}
end

function ActionBarsManager:Save()
    local actionBars = {}
    RuilhennDB.actionBars = RuilhennDB.actionBars or {}
    local _, playerClass = UnitClass("player")
    local currentSpec = GetSpecialization()

    ns.Log:Message(ns.L["CLASS_DETECTED"]:format(playerClass))
    for _, barNumber in pairs(self.MANAGED_BARS) do
        local startSlot, endSlot = self:GetActionBarSlots(barNumber)
        -- ns.Log:Debug("barNumber: " .. barNumber .. " => Save from " .. startSlot .. " to " .. endSlot)
        local actions = {}
        for i = startSlot, endSlot do
            local actionBarInfo = self:GetActionBarInfo(i)
            if actionBarInfo.type and actionBarInfo.id then
                actions[i - startSlot + 1] = actionBarInfo
            else
                actions[i - startSlot + 1] = {}
            end
        end
        actionBars[barNumber] = actions
    end

    if not RuilhennDB.actionBars[playerClass] then
        RuilhennDB.actionBars[playerClass] = {}
    end

    RuilhennDB.actionBars[playerClass][currentSpec] = actionBars
    ns.Log:Message(ns.L["ACTIONBARS_SAVED"])
end

function ActionBarsManager:Load()
    if InCombatLockdown() then
        ns.Log:Error(ns.L["ERR_IN_COMBAT"] or "Cannot restore action bars in combat.")
        return
    end

    local _, playerClass = UnitClass("player")
    local currentSpec = GetSpecialization()
    RuilhennDB.actionBars = RuilhennDB.actionBars or {}

    ns.Log:Message(ns.L["CLASS_DETECTED"]:format(playerClass))

    if RuilhennDB.actionBars[playerClass] then
        local actionBars = RuilhennDB.actionBars[playerClass][currentSpec]
        if actionBars then
            for barNumber, actionBar in ipairs(actionBars) do

                local startSlot, endSlot = self:GetActionBarSlots(barNumber)
                for i = startSlot, endSlot do
                    local action = actionBar[i - startSlot + 1]
                    if action.type and action.id then
                        -- ns.Log:Debug("Placing action at position " .. i .. " with type " .. action.type .. " and id " .. action.id)
                        self:PlaceActionSafely(i, action.id, action.type)
                    end
                end
            end
            ns.Log:Message(ns.L["ACTIONBARS_LOADED"])
        end
    end
end

function ActionBarsManager:GetActionBarSlots(barNumber)
    if not self.ACTION_BAR_SLOTS[barNumber] then
        ns.Log:Error(ns.L["INVALID_ACTION_BAR"]:format(barNumber))
        return nil
    end

    return self.ACTION_BAR_SLOTS[barNumber].start, self.ACTION_BAR_SLOTS[barNumber]["end"]
end

function ActionBarsManager:Clear(...)
    local bars = {...}
    if #bars == 0 then
        -- If no bars specified, clear all
        bars = ns.Utils:Map(tostring, self.MANAGED_BARS)
    end

    local totalCleared = 0

    for _, barString in pairs(bars) do
        local barNumber = tonumber(barString)
        local startSlot, endSlot = self:GetActionBarSlots(barNumber)
        -- ns.Log:Debug("barNumber: " .. barNumber .. " => Clear from " .. startSlot .. " to " .. endSlot)
        if startSlot then
            for slot = startSlot, endSlot do
                    if GetActionInfo(slot) then
                        PickupAction(slot)
                        ClearCursor()
                        totalCleared = totalCleared + 1
                    end

            end
        end
    end
end

ActionBarsManager.subcommands = {
    ["load"] = function()
        ActionBarsManager:Load()
    end,
    ["save"] = function()
        ActionBarsManager:Save()
    end,
    ["clear"] = function(...)
        ActionBarsManager:Clear(...)
    end
}

Commands["bars"] = function(subcommand, ...)
    local func = ActionBarsManager.subcommands[subcommand]
    if type(func) ~= "function" then
        return
    end

    local success, err = pcall(func, ...)
    if not success then
        ns.Log:Debug("Command execution error: " .. err)
    end
end