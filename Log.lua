-- Log.lua
local _, ns = ...
local Log = ns.Log

function Log:Message(message)
    print("|cff00ff00Ruilhenn:|r " .. message)
end

function Log:Debug(message)
    if ns.Config.debugMode then
        print("|cfff488f0Ruilhenn:|r " .. message)
    end
end

function Log:Error(message)
    print("|cffff0000Ruilhenn Error:|r " .. message)
end

function Log:Warning(message)
    print("|cffffa500Ruilhenn Warning:|r " .. message)
end