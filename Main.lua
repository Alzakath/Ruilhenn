-- Main.lua
local _, ns = ...

-- WoW API
local SlashCmdList = SlashCmdList
local CreateFrame = CreateFrame
local UnitClass = UnitClass
local debugprofilestop = debugprofilestop

local Ruilhenn = CreateFrame("Frame", "RuilhennFrame")

RuilhennDB = RuilhennDB or {}

Ruilhenn.command = {
    ["debug"] = function(subcommand)

        if subcommand == "st atus" then
            if ns.Config.debugMode then
                ns.Log:Message(ns.L["DEBUG_ACTIVATED"])
            else
                ns.Log:Message(ns.L["DEBUG_DEACTIVATED"])
            end
            return
        end

        ns.Config.debugMode = not ns.Config.debugMode
        ns.Config:SaveSetting("debugMode", ns.Config.debugMode)
        if ns.Config.debugMode then
            ns.Log:Message(ns.L["DEBUG_ACTIVATED"])
        else
            ns.Log:Message(ns.L["DEBUG_DEACTIVATED"])
        end
    end
}

function Ruilhenn:Command(msg)

    local lmsg = msg:lower()
    local cmd, args = ns.Utils:UnpackFirst(ns.Utils:SplitWhitespace(lmsg))

    local func = self.command[cmd]


    if type(func) ~= "function" then
        self:CommandUsage()
        return
    end

    local success, err = pcall(func, unpack(args))
    if not success then
        ns.Log:Debug("Command execution error: " .. err)
    end
end

function Ruilhenn:PrintGreetings()
    local version = '0.1.0'
    ns.Log:Message(ns.L["LOADED"]:format(version))
    ns.Log:Message(ns.L["STARTED"])
end

function Ruilhenn:CommandUsage()
    ns.Log:Message("Usage:")
    ns.Log:Message("/ruil debug - " .. ns.L["COMMAND_DEBUG_HELP"])
    ns.Log:Message("/ruil debug status - " .. ns.L["COMMAND_STATUS_HELP"])
end

function Ruilhenn:OnEvent(event, ...)
    self[event](self, event, ...)
end

function Ruilhenn:RegisterCommands()
    ns.Log:Debug("RegisterCommands => " .. ns.Utils:DumpTable(ns.Commands))
    for cmd, func in pairs(ns.Commands) do
        self.command[cmd] = func
        ns.Log:Debug("Registered command: " .. cmd)
    end
end

function Ruilhenn:ADDON_LOADED(event, addon)
    if addon ~= "Ruilhenn" then return end
    ns.Config:LoadSavedVariables()
    self:PrintGreetings()
    self:RegisterCommands()

    local endTime = debugprofilestop()
    ns.Log:Debug(ns.L["LOADED_TIMER"]:format(endTime - ns.startTime))
end

Ruilhenn:RegisterEvent("ADDON_LOADED")
Ruilhenn:SetScript("OnEvent", Ruilhenn.OnEvent)

SLASH_RUILHENN1 = "/ruil"
SLASH_RUILHENN2 = "/ruilhenn"

SlashCmdList["RUILHENN"] = function(msg)
    Ruilhenn:Command(msg)
end
