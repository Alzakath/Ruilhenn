RuilhennDB = RuilhennDB or {}

local CreateFrame = CreateFrame
local GetMacroInfo = GetMacroInfo
local EditMacro = EditMacro
local CreateMacro = CreateMacro
local SlashCmdList = SlashCmdList
local GetLocale = GetLocale
local UnitClass = UnitClass
local GetFramerate = GetFramerate
local UnitName = UnitName
local GetSpellName = C_Spell.GetSpellName
local GetItemInfo = C_Item.GetItemInfo
local debugprofilestop = debugprofilestop

local RuilhennLocale = RuilhennLocale
local MacroTemplates = MacroTemplates

local locale = GetLocale()
local L = setmetatable(RuilhennLocale[locale] or {}, { __index = RuilhennLocale["enUS"] })
local taskFrame = CreateFrame("Frame", "RuilhennTaskFrame")
local startTime = START_TIME

Ruilhenn = CreateFrame("Frame", "RuilhennFrame")
Ruilhenn.debugMode = false
Ruilhenn.command = {
    ["debug"] = "ToggleDebugMode",
    ["status"] = "DebugModeStatus",
    ["init"] = "InitMacros",
}

function Ruilhenn:Command(msg)
    local funcName = self.command[msg:lower()]
    local func = self[funcName]

    if type(func) ~= "function" then
        self:CommandUsage()
        return
    end

    local success, err = pcall(func, self)
    if not success then
        self:Debug("Command execution error: " .. err)
    end
end

function Ruilhenn:CommandUsage()
    self:Message("Usage:")
    self:Message("/ruil debug - " .. L["COMMAND_DEBUG_HELP"])
    self:Message("/ruil status - " .. L["COMMAND_STATUS_HELP"])
    self:Message("/ruil init - " .. L["COMMAND_INIT_HELP"])
end

function Ruilhenn:ToggleDebugMode()
    self.debugMode = not self.debugMode
    if self.debugMode then
        self:Message("|cff00ff00Ruilhenn:|r " .. L["DEBUG_ACTIVATED"])
    else
        self:Message("|cff00ff00Ruilhenn:|r " .. L["DEBUG_DEACTIVATED"])
    end

    self:SaveSetting("debugMode", self.debugMode)
end

function Ruilhenn:DebugModeStatus()
    if self.debugMode then
        self:Message("|cff00ff00Ruilhenn:|r " .. L["DEBUG_ACTIVATED"])
    else
        self:Message("|cff00ff00Ruilhenn:|r " .. L["DEBUG_DEACTIVATED"])
    end
end

function Ruilhenn:Message(message)
    print(message)
end

function Ruilhenn:Debug(message)
    if self.debugMode then
        print("|cfff488f0Ruilhenn:|r " .. message)
    end
end

function Ruilhenn:Log(message)
    print("|cff00ff00Ruilhenn:|r " .. message)
end

function Ruilhenn:Error(message)
    print("|cffff0000Ruilhenn Error:|r " .. message)
end

function Ruilhenn:Warning(message)
    print("|cffffa500Ruilhenn Warning:|r " .. message)
end

function Ruilhenn:DumpTable(value)
    if type(value) == 'table' then
        local s = '{ '
        for k, v in pairs(value) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. self:DumpTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(value)
    end
end

function Ruilhenn:PrintGreetings()
    local version = '0.0.4'
    self:Log(L["LOADED"]:format(version))
    self:Log(L["STARTED"])
end

function Ruilhenn:ReplaceSpellIDs(macroBody)
    -- This pattern matches "%spell:ID%" where ID is the spell ID
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

function Ruilhenn:EnsureMacroExists(macro)
    local localizedBody = self:ReplaceSpellIDs(macro.body)
    local macroIndex = Ruilhenn:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        CreateMacro(macro.name, macro.icon, localizedBody, true)
        self:Debug(L["MACRO_CREATED"]:format(macro.name))
    else
        EditMacro(macroIndex, macro.name, macro.icon, localizedBody)
        self:Debug(L["MACRO_UPDATED"]:format(macro.name))
    end
end

function Ruilhenn:CreateTaskQueue(initialTasksPerFrame)
    local queue = { tasks = {}, tasksPerFrame = initialTasksPerFrame or 5 }

    function queue:AddTask(task)
        table.insert(self.tasks, task)
    end

    function queue:Process()
        local tasksProcessed = 0
        while tasksProcessed < self.tasksPerFrame and #self.tasks > 0 do
            local task = table.remove(self.tasks, 1)
            local success, err = pcall(task)
            if not success then
                Ruilhenn:Error(L["TASKS_ERROR"]:format(err))
            end
            tasksProcessed = tasksProcessed + 1
        end
        if #self.tasks == 0 then
            taskFrame:SetScript("OnUpdate", nil)
            Ruilhenn:Debug(L["TASKS_PROCESSED"])
        end
    end

    function queue:Run()
        if #self.tasks > 0 then
            taskFrame:SetScript("OnUpdate", function()
                local fps = GetFramerate()
                self.tasksPerFrame = math.max(1, math.floor(fps / 10))
                self:Process()
            end)
        end
    end

    return queue
end

function Ruilhenn:CreateClassMacros(classMacros)
    local taskQueue = self:CreateTaskQueue(5)

    for _, macro in ipairs(classMacros) do
        taskQueue:AddTask(function()
            self:EnsureMacroExists(macro)
        end)
    end
    taskQueue:Run()
end

function Ruilhenn:FindCharacterMacro(macroName)
    for i = 1, NUM_CHARACTER_MACROS do
        local macroIndex = i + FIRST_CHARACTER_MACRO_INDEX - 1
        local name = GetMacroInfo(macroIndex)
        if name == macroName then
            return macroIndex
        end
    end
    return 0
end

function Ruilhenn:OnEvent(event, ...)
    self[event](self, event, ...)
end

function Ruilhenn:LoadSavedVariables()
    local playerName = UnitName("player")
    RuilhennDB.playerSettings = RuilhennDB.playerSettings or {}
    local settings = RuilhennDB.playerSettings[playerName] or {}

    self.debugMode = settings.debugMode or false

    if settings then
        self:Debug(L["SETTINGS_FOUND"]:format(playerName))
    else
        self:Debug(L["SETTINGS_NOT_FOUND"]:format(playerName))
    end
end

function Ruilhenn:SaveSetting(key, value)
    local playerName = UnitName("player")
    RuilhennDB.playerSettings[playerName] = RuilhennDB.playerSettings[playerName] or {}

    RuilhennDB.playerSettings[playerName][key] = value
end

function Ruilhenn:ADDON_LOADED(event, addon)
    if addon ~= "Ruilhenn" then return end

    self:PrintGreetings()
    self:LoadSavedVariables()
    local endTime = debugprofilestop()
    self:Debug(L["LOADED_TIMER"]:format(endTime - startTime))
end

function Ruilhenn:InitMacros()
    local _, playerClass = UnitClass("player")
    self:Log(L["CLASS_DETECTED"]:format(playerClass))

    local macroGenerator = MacroTemplates[playerClass]

    if macroGenerator then
        self:CreateClassMacros(macroGenerator())
    else
        self:Warning(L["NO_MACROS_DEFINED"]:format(playerClass))
    end
end

Ruilhenn:RegisterEvent("ADDON_LOADED")
Ruilhenn:SetScript("OnEvent", Ruilhenn.OnEvent)

SLASH_RUILHENN1 = "/ruil"
SLASH_RUILHENN2 = "/ruilhenn"

SlashCmdList["RUILHENN"] = function(msg)
    Ruilhenn:Command(msg)
end
