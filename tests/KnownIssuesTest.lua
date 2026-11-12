-- These desired-behavior tests intentionally fail until the associated bugs are fixed.
-- Run explicitly: lua tests/run.lua --known-issues
local T, fixture = ...

T.test("#17: missing item data never persists UnknownItem into a macro", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    ns.MacroManager:EnsureMacroExists({ name = "item", icon = 123, body = "/use %item:99%" })
    for _, macro in ipairs(s.created) do
        assert(not macro[3]:find("UnknownItem", 1, true), "uncached item persisted as UnknownItem")
    end
end)

T.test("#18: clearing bars in combat preserves both slots and cursor", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1], s.cursor, s.combat = { "spell", 42 }, { "item", 99 }, true
    ns.ActionBarsManager:Clear("1")
    T.equal(#s.pickups, 0)
    T.equal(s.slots[1][2], 42)
    T.equal(s.cursor[2], 99)
end)

T.test("Untracked: invalid bar numbers report an error without throwing", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1] = { "spell", 42 }
    ns.ActionBarsManager:Clear("99")
    T.equal(#s.pickups, 0)
    T.equal(s.slots[1][2], 42)
    T.contains(s.output[#s.output], "99")
end)

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
