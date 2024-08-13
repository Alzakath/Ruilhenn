Ruilhenn = CreateFrame("Frame", "RuilhennFrame")

local locale = GetLocale()
local L = Ruilhenn_Locale[locale] or Ruilhenn_Locale["enUS"] -- English as default locale

function Ruilhenn:Log(message)
    print("|cff00ff00Ruilhenn:|r " .. message)
end

function Ruilhenn:Error(message)
    print("|cffff0000Ruilhenn Error:|r " .. message)
end

function Ruilhenn:Warning(message)
    print("|cffffa500Ruilhenn Warning:|r " .. message)
end

function Ruilhenn:PrintHelloWorld()
    Ruilhenn:Log(L["LOADED"])
end

function Ruilhenn:EnsureMacroExists(macro)
    local macroIndex = Ruilhenn:FindCharacterMacro(macro.name)

    if macroIndex == 0 then
        -- Create a new macro if it doesn't exist
        CreateMacro(macro.name, macro.icon, macro.body, true)
        Ruilhenn:Log(L["MACRO_CREATED"]:format(macro.name))
    else
        -- Update existing macro
        EditMacro(macroIndex, macro.name, macro.icon, macro.body)
        Ruilhenn:Log(L["MACRO_UPDATED"]:format(macro.name))
    end
end

function Ruilhenn:ProcessMacros(classMacros)
    for _, macro in ipairs(classMacros) do
        Ruilhenn:EnsureMacroExists(macro)
        coroutine.yield()
    end
end

function Ruilhenn:StartCoroutine(coroutineFunc)
    local co = coroutine.create(coroutineFunc)

    local function OnUpdate(self, elapsed)
        if coroutine.status(co) ~= "dead" then
            local success, err = coroutine.resume(co)
            if not success then
                Ruilhenn:Error(L["ERROR_COROUTINE"]:format(err))
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

function Ruilhenn:SPELLS_CHANGED(event)
end

function Ruilhenn:ADDON_LOADED(event, addon)
    if addon == "Ruilhenn" then
        Ruilhenn:PrintHelloWorld()
    end
end

function Ruilhenn:PLAYER_ENTERING_WORLD(event)
    local _, playerClass = UnitClass("player")
    Ruilhenn:Log(L["CLASS_DETECTED"]:format(playerClass))

    if MacroTemplates[playerClass] then
        Ruilhenn:CreateClassMacros(MacroTemplates[playerClass])
    else
        Ruilhenn:Warning(L["NO_MACROS_DEFINED"]:format(playerClass))
    end
end

Ruilhenn:RegisterEvent("SPELLS_CHANGED")
Ruilhenn:RegisterEvent("ADDON_LOADED")
Ruilhenn:RegisterEvent("PLAYER_ENTERING_WORLD")

Ruilhenn:SetScript("OnEvent", Ruilhenn.OnEvent)

