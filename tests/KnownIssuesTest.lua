-- These desired-behavior tests intentionally fail until the associated bugs are fixed.
-- Run explicitly: lua tests/run.lua --known-issues
local T, fixture = ...

T.test("Untracked: EventManager debug toggle works with the production logger", function()
    local _, ns, _, load = fixture(T)
    load("TaskQueue.lua")
    load("EventManager.lua")
    local manager = ns.EventManager:New()
    manager:SetDebugMode(false)
    T.equal(manager.debugMode, false)
end)

T.test("Stock Lua 5.1: event delivery does not require table.unpack", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    load("EventManager.lua")
    local manager, received = ns.EventManager:New(), false
    manager:RegisterEvent("READY", function() received = true end)
    manager:FireEvent("READY")
    s:drain()
    T.equal(received, true)
end)
