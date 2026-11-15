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
    
end

function Config:SaveSetting(key, value)
    local playerName = UnitName("player")
    RuilhennDB.playerSettings[playerName] = RuilhennDB.playerSettings[playerName] or {}
    RuilhennDB.playerSettings[playerName][key] = value
end
