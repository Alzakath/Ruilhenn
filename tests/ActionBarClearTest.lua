local T, fixture = ...

T.test("#18: combat clear preserves every slot, cursor and pending restore", function()
    for _, all in ipairs({ false, true }) do
        local _, ns, s, load = fixture(T)
        load("ActionBarsManager.lua")
        local token = {}
        ns.ActionBarsManager.restoreToken = token
        s.slots[1], s.cursor, s.combat = { "spell", 42 }, { "item", 99 }, true
        local result
        if all then result = ns.ActionBarsManager:Clear() else result = ns.ActionBarsManager:Clear("1") end
        T.equal(result, false)
        T.equal(#s.pickups, 0)
        T.equal(s.slots[1][2], 42)
        T.equal(s.cursor[2], 99)
        T.equal(ns.ActionBarsManager.restoreToken, token)
        T.contains(s.output[#s.output], "combat")
    end
end)

T.test("#18: selected clearing removes only occupied requested slots", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1], s.slots[12], s.slots[13] = { "spell", 42 }, { "item", 99 }, { "spell", 43 }
    s.cursor = { "spell", 44 }
    T.equal(ns.ActionBarsManager:Clear("1"), 2)
    T.equal(s.slots[1], nil)
    T.equal(s.slots[12], nil)
    T.equal(s.slots[13][2], 43)
    T.equal(s.cursor, nil)
end)

T.test("#18: default clearing reaches extra bars and preserves unmanaged slots", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    for _, slot in ipairs({ 1, 145, 180, 121 }) do s.slots[slot] = { "spell", slot } end
    T.equal(ns.ActionBarsManager:Clear(), 3)
    T.equal(s.slots[1], nil)
    T.equal(s.slots[145], nil)
    T.equal(s.slots[180], nil)
    T.equal(s.slots[121][2], 121)
end)

T.test("#18: all bar arguments are validated before mutating slots or cursor", function()
    for _, invalid in ipairs({ "99", "invalid" }) do
        local _, ns, s, load = fixture(T)
        load("ActionBarsManager.lua")
        s.slots[1], s.cursor = { "spell", 42 }, { "item", 99 }
        T.equal(ns.ActionBarsManager:Clear("1", invalid), false)
        T.equal(#s.pickups, 0)
        T.equal(s.slots[1][2], 42)
        T.equal(s.cursor[2], 99)
        T.contains(s.output[#s.output], invalid)
    end
end)

T.test("#18: a rejected pickup is reported rather than counted as cleared", function()
    local env, ns, s, load = fixture(T)
    env.PickupAction = function() end
    load("ActionBarsManager.lua")
    s.slots[1] = { "spell", 42 }
    T.equal(ns.ActionBarsManager:Clear("1"), 0)
    T.equal(s.slots[1][2], 42)
    T.contains(s.output[#s.output], "Failed to clear")
end)
