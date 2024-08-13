Ruilhenn = CreateFrame("Frame", "RuilhennFrame")
Ruilhenn.debugMode = false
Ruilhenn.command = {
    ["debug"] = "ToggleDebugMode",
    ["status"] = "DebugModeStatus",
    ["init"] = "InitMacros",
}

local locale = GetLocale()
local L = setmetatable(Ruilhenn_Locale[locale] or {}, {__index = Ruilhenn_Locale["enUS"]})

function Ruilhenn:Command(msg)
    local funcName = self.command[msg:lower()]
    local func = self[funcName]
    if type(func) == "function" then
        func(self)
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
    local version = GetAddOnMetadata("Ruilhenn", "Version")
    self:Log(L["LOADED"]:format(version))
    self:Log(L["STARTED"])
end

function Ruilhenn:EnsureMacroExists(macro)
    local macroIndex = Ruilhenn:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        -- Create a new macro if it doesn't exist
        CreateMacro(macro.name, macro.icon, macro.body, true)
        self:Log(L["MACRO_CREATED"]:format(macro.name))
    else
        -- Update existing macro
        EditMacro(macroIndex, macro.name, macro.icon, macro.body)
        self:Log(L["MACRO_UPDATED"]:format(macro.name))
    end
end

function Ruilhenn:ProcessMacros(classMacros)
    for _, macro in ipairs(classMacros) do
        self:EnsureMacroExists(macro)
        coroutine.yield()
    end
end

function Ruilhenn:StartCoroutine(coroutineFunc)
    local co = coroutine.create(coroutineFunc)

    local function OnUpdate(self, elapsed)
        if coroutine.status(co) ~= "dead" then
            local success, err = coroutine.resume(co)
            if not success then
                self:Error(L["ERROR_COROUTINE"]:format(err))
            end
        else
            self:SetScript("OnUpdate", nil)
        end
    end

    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", OnUpdate)
end

function Ruilhenn:CreateClassMacros(classMacros)
    self:StartCoroutine(function()
        self:ProcessMacros(classMacros)
    end)
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
