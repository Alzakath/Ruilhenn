local CreateFrame = CreateFrame
local GetMacroInfo = GetMacroInfo
local EditMacro = EditMacro
local CreateMacro = CreateMacro
local SlashCmdList = SlashCmdList
local GetLocale = GetLocale
local UnitClass = UnitClass
local GetFramerate = GetFramerate

local Ruilhenn_Locale = Ruilhenn_Locale
local MacroTemplates = MacroTemplates

local locale = GetLocale()
local L = setmetatable(Ruilhenn_Locale[locale] or {}, { __index = Ruilhenn_Locale["enUS"] })
local taskFrame = CreateFrame("Frame", "RuilhennTaskFrame")

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
    if type(func) == "function" then
        local success, err = pcall(func, self)
        if not success then
            self:Debug("Command execution error: " .. err)
        end
    else
        self:CommandUsage()
    end
end

function Ruilhenn:CommandUsage()
    self:Message("Usage:")
    self:Message("/ruil debug - Toggle debug mode.")
    self:Message("/ruil status - Show debug mode status.")
    self:Message("/ruil init - Create or Update class specific macros.")
end

function Ruilhenn:ToggleDebugMode()
    self.debugMode = not self.debugMode
    if self.debugMode then
        self:Message("|cff00ff00Ruilhenn:|r Debug mode |cff00ff00activated|r")
    else
        self:Message("|cff00ff00Ruilhenn:|r Debug mode |cffff0000deactivated|r")
    end
end

function Ruilhenn:DebugModeStatus()
    if self.debugMode then
        self:Message("|cff00ff00Ruilhenn:|r Debug mode is currently |cff00ff00ON|r")
    else
        self:Message("|cff00ff00Ruilhenn:|r Debug mode is currently |cffff0000OFF|r")
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

function Ruilhenn:PrintGreetings()
    local version = '0.0.2'
    self:Log(L["LOADED"]:format(version))
    self:Log(L["STARTED"])
end

function Ruilhenn:EnsureMacroExists(macro)
    local macroIndex = Ruilhenn:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        CreateMacro(macro.name, macro.icon, macro.body, true)
        self:Debug(L["MACRO_CREATED"]:format(macro.name))
    else
        EditMacro(macroIndex, macro.name, macro.icon, macro.body)
        self:Debug(L["MACRO_UPDATED"]:format(macro.name))
    end
end

function Ruilhenn:CreateMacrosQueue(initialTasksPerFrame)
    local taskQueue = { tasks = {}, tasksPerFrame = initialTasksPerFrame or 5}

    function taskQueue:AddTask(task)
        table.insert(self.tasks, task)
    end

    function taskQueue:Process()
        local tasksProcessed = 0
        while tasksProcessed < self.tasksPerFrame and #self.tasks > 0 do
            local task = table.remove(self.tasks, 1)
            local success, err = pcall(task)
            if not success then
                Ruilhenn:Error("Task error: " .. err)
            end
            tasksProcessed = tasksProcessed + 1
        end
        if #self.tasks == 0 then
            taskFrame:SetScript("OnUpdate", nil)
            Ruilhenn:Debug("All tasks processed.")
        end
    end

    function taskQueue:Run()
        if #self.tasks > 0 then
            taskFrame:SetScript("OnUpdate", function()
                local fps = GetFramerate()
                self.tasksPerFrame = math.max(1, math.floor(fps / 10))
                self:Process()
            end)
        end
    end

    return taskQueue
end

function Ruilhenn:CreateClassMacros(classMacros)
    local taskQueue = self:CreateMacrosQueue(5)

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

function Ruilhenn:ADDON_LOADED(event, addon)
    if addon ~= "Ruilhenn" then return end

    self:PrintGreetings()
end

function Ruilhenn:InitMacros()
    local _, playerClass = UnitClass("player")
    self:Log(L["CLASS_DETECTED"]:format(playerClass))

    if MacroTemplates[playerClass] then
        self:CreateClassMacros(MacroTemplates[playerClass])
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
