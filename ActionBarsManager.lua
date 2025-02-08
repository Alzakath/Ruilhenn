-- ActionBarsManager.lua
local _, ns = ...
local ActionBarsManager = ns.ActionBarsManager
local Commands = ns.Commands

-- WoW API
local UnitClass = UnitClass
local GetMacroInfo = GetMacroInfo
local GetNumBindings = GetNumBindings
local GetBinding = GetBinding
local SetBinding = SetBinding
local SaveBindings = SaveBindings
local GetCurrentBindingSet = GetCurrentBindingSet
local GetActionInfo = GetActionInfo
local PlaceAction = PlaceAction
local ClearCursor = ClearCursor
local GetSpellInfo = C_Spell.GetSpellInfo
local PickupSpell = C_Spell.PickupSpell
local PickupItem = PickupItem
local PickupMacro = PickupMacro
local PickupAction = PickupAction
local GetSpellName = C_Spell.GetSpellName
local GetItemInfo = C_Item.GetItemInfo

function ActionBarsManager:PlaceActionSafely(slot, actionId, actionType)
    if not slot or slot < 1 or slot > 120 then
        self:Error(L["INVALID_ACTION_SLOT"]:format(slot or "nil"))
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
            self:Error(L["SPELL_NOT_FOUND"]:format(actionId))
        end
    elseif actionType == "item" then
        -- Handle item placement
        local itemInfo = GetItemInfo(actionId)
        if itemInfo then
            PickupItem(actionId)
            success = true
            actionName = itemInfo[1] or ""
        else
            self:Error(L["ITEM_NOT_FOUND"]:format(actionId))
        end
    elseif actionType == "macro" then
        -- Handle macro placement
        local macroInfo = GetMacroInfo(actionId)
        if macroInfo then
            PickupMacro(actionId)
            success = true
            actionName = macroInfo[0] or ""
        else
            self:Error(L["MACRO_NOT_FOUND"]:format(actionId))
        end
    else
        self:Error(L["INVALID_ACTION_TYPE"]:format(actionType))
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
            self:Error(L["ACTION_PLACED_FAILED"]:format(actionType, actionName, actionId, slot))
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

    for i = 1, 120 do
        local type, id = GetActionInfo(i)
        if id then
            actionBars[i] = { type = type, id = id }
        else
            actionBars[i] = {}
        end
    end
    RuilhennDB.actionBars[playerClass] = actionBars
    ns.Log:Debug(L["ACTIONBARS_SAVED"])
end

function ActionBarsManager:Load()
    local _, playerClass = UnitClass("player")
    RuilhennDB.actionBars = RuilhennDB.actionBars or {}
    local actionBars = RuilhennDB.actionBars[playerClass] or {}

    if actionBars then
        for i, action in ipairs(actionBars) do
            if action.type and action.id then
                ns.Log:Debug("Placing action at position " .. i .. " with type " .. action.type .. " and id " .. action.id)
                self:PlaceActionSafely(i, action.id, action.type)
            end
        end
        ns.Log:Debug(L["ACTIONBARS_LOADED"])
    end
end

function ActionBarsManager:Clear()
    local clearedCount = 0
    for slot = 1, 120 do
        local actionType = GetActionInfo(slot)

        if actionType then
            ns.Log:Debug("clearing slot " .. slot .. " with type " .. actionType)
            PickupAction(slot)
            ClearCursor()
            clearedCount = clearedCount + 1
        end
    end
    ns.Log:Debug("bars cleared: " .. clearedCount)
end

ActionBarsManager.subcommands = {
    ["load"] = function()
        ns.Log:Debug("ActionBarsManager:Load")
    end,
    ["save"] = function()
        ns.Log:Debug("ActionBarsManager:Save")
    end,
    ["clear"] = function()
        ns.Log:Debug("ActionBarsManager:Clear")
    end
}

Commands["bars"] = function(subcommand)
    local func = ActionBarsManager.subcommands[subcommand]

    if type(func) ~= "function" then
        return
    end

    local success, err = pcall(func)
    if not success then
        ns.Log:Debug("Command execution error: " .. err)
    end
end