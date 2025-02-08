-- Config.lua
local _, ns = ...
local Config = ns.Config

-- WoW API
local UnitName = UnitName

function Config:LoadSavedVariables()
    local playerName = UnitName("player")
    RuilhennDB.playerSettings = RuilhennDB.playerSettings or {}
    local settings = RuilhennDB.playerSettings[playerName] or {}
    
    self.debugMode = settings.debugMode or false
    
    if settings then
        ns.Log:Debug(ns.L["SETTINGS_FOUND"]:format(playerName))
    else
        ns.Log:Debug(ns.L["SETTINGS_NOT_FOUND"]:format(playerName))
    end
end

function Config:SaveSetting(key, value)
    local playerName = UnitName("player")
    RuilhennDB.playerSettings[playerName] = RuilhennDB.playerSettings[playerName] or {}
    RuilhennDB.playerSettings[playerName][key] = value
end
