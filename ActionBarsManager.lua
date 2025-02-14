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
local GetTime = GetTime

ActionBarsManager.ACTION_BAR_SLOTS = {
    [1] = {start = 1, ["end"] = 12},
    [2] = {start = 61, ["end"] = 72},
    [3] = {start = 49, ["end"] = 60},
    [4] = {start = 25, ["end"] = 36},
    [5] = {start = 37, ["end"] = 48},
    [6] = {start = 145, ["end"] = 156},
    [7] = {start = 157, ["end"] = 168},
    [8] = {start = 169, ["end"] = 180}
}

ActionBarsManager.MANAGED_BARS = {1, 2, 3, 4, 5, 6, 7, 8}

function ActionBarsManager:PlaceActionSafely(slot, actionId, actionType)
    if not slot or slot < 1 or slot > 180 then
        ns.Log:Error(L["INVALID_ACTION_SLOT"]:format(slot or "nil"))
        return false
    end

    -- Clear the cursor before starting
    ClearCursor()

    local success = false
    local actionName = ""
    
    if actionType == "spell" then
        -- Handle spell placement
        local spellInfo = GetSpellInfo(actionId)
        if spellInfo then
            PickupSpell(actionId)
            success = true
            actionName = spellInfo.name or ""
        else
            ns.Log:Error(L["SPELL_NOT_FOUND"]:format(actionId))
        end
    elseif actionType == "item" then
        -- Handle item placement
        local itemInfo = GetItemInfo(actionId)
        if itemInfo then
            PickupItem(actionId)
            success = true
            actionName = itemInfo[1] or ""
        else
            ns.Log:Error(L["ITEM_NOT_FOUND"]:format(actionId))
        end
    elseif actionType == "macro" then
        -- Handle macro placement
        local macroInfo = GetMacroInfo(actionId)
        if macroInfo then
            PickupMacro(actionId)
            success = true
            actionName = macroInfo[0] or ""
        else
            ns.Log:Error(ns.L["MACRO_NOT_FOUND"]:format(actionId))
        end
    else
        ns.Log:Error(ns.L["INVALID_ACTION_TYPE"]:format(actionType))
        return false
    end

    if success then
        -- Place the action
        PlaceAction(slot)
        -- Verify placement
        local placedType, placedId = GetActionInfo(slot)
        if placedType == actionType and placedId == actionId then
            return true
        else
            ns.Log:Error(ns.L["ACTION_PLACED_FAILED"]:format(actionType, actionName, actionId, slot))
        end
    end

    -- Clear cursor if placement failed
    ClearCursor()
    return false
end

function ActionBarsManager:Save()
    local actionBars = {}
    RuilhennDB.actionBars = RuilhennDB.actionBars or {}
    local _, playerClass = UnitClass("player")

    for barNumber = 1, 8 do
        local startSlot, endSlot = self:GetActionBarSlots(barNumber)
        local actions = {}
        for i = startSlot, endSlot do
            local type, id = GetActionInfo(i)
            if type and id then
                actions[i - startSlot + 1] = { type = type, id = id }
            else
                actions[i - startSlot + 1] = {}
            end
        end
        actionBars[barNumber] = actions
    end

    RuilhennDB.actionBars[playerClass] = actionBars
    ns.Log:Debug(ns.L["ACTIONBARS_SAVED"])
end

function ActionBarsManager:Load()
    local _, playerClass = UnitClass("player")
    RuilhennDB.actionBars = RuilhennDB.actionBars or {}
    local actionBars = RuilhennDB.actionBars[playerClass] or {}

    if actionBars then
        for barNumber, actionBar in ipairs(actionBars) do

            local startSlot, endSlot = self:GetActionBarSlots(barNumber)
            for i = startSlot, endSlot do
                local action = actionBar[i - startSlot + 1]
                if action.type and action.id then
                    ns.Log:Debug("Placing action at position " .. i .. " with type " .. action.type .. " and id " .. action.id)
                    self:PlaceActionSafely(i, action.id, action.type)
                end
            end
        end
        ns.Log:Debug(ns.L["ACTIONBARS_LOADED"])
    end
end

function ActionBarsManager:GetActionBarSlots(barNumber)
    if not self.ACTION_BAR_SLOTS[barNumber] then
        ns.Log:Error(L["INVALID_ACTION_BAR"]:format(barNumber))
        return nil
    end

    return self.ACTION_BAR_SLOTS[barNumber].start, self.ACTION_BAR_SLOTS[barNumber]["end"]
    -- return (barNumber - 1) * 12 + 1, barNumber * 12
end

function ActionBarsManager:Clear(...)
    local bars = {...}
    if #bars == 0 then
        -- If no bars specified, clear all
        bars = ns.Utils:Map(tostring, self.MANAGED_BARS)
    end

    local queue = ns.TaskQueue:New(5)
    local totalCleared = 0
    local startTime = GetTime()

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