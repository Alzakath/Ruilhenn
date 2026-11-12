local T, fixture = ...
local macro = { name = "item", icon = 123, body = "/use %item:99%" }

T.test("#17: cold item macros wait, then use the resolved localized item name", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    ns.MacroManager:EnsureMacroExists(macro)
    T.equal(#s.created, 0)
    T.equal(s.itemRequests[1], 99)
    s:resolveItem(99, "Objet de test")
    T.equal(#s.created, 1)
    T.equal(s.created[1][3], "/use Objet de test")
    s:resolveItem(99, "Objet de test")
    T.equal(#s.created, 1)
end)

T.test("#17: failed, timed-out and unreadable item data never persists a placeholder", function()
    for _, outcome in ipairs({ "failure", "timeout", "no-name" }) do
        local _, ns, s, load = fixture(T)
        load("MacroManager.lua")
        ns.MacroManager:EnsureMacroExists(macro)
        if outcome == "timeout" then s:expireTimers()
        else s:resolveItem(99, nil, outcome ~= "failure") end
        T.equal(#s.created, 0)
        T.equal(#s.edited, 0)
        T.contains(s.output[#s.output], "Could not load item data")
        s:resolveItem(99, "Late item")
        T.equal(#s.created, 0)
    end
end)

T.test("#17: item batches deduplicate IDs and wait for every result", function()
    local _, ns, s = fixture(T)
    local calls, names = 0, nil
    ns.ItemData:WithNames({ 99, 100, 99 }, function(value) calls = calls + 1; names = value end)
    T.equal(#s.itemRequests, 2)
    s:resolveItem(999, "Unrelated")
    s:resolveItem(100, "Second")
    T.equal(calls, 0)
    s:resolveItem(99, "First")
    T.equal(calls, 1)
    T.equal(names[99], "First")
    T.equal(names[100], "Second")
    s:expireTimers()
    T.equal(calls, 1)
end)

local function bars()
    local env, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.spells[42] = "Spell"
    s.slots[1], s.slots[2] = { "spell", 42 }, { "item", 99 }
    ns.ActionBarsManager:Save()
    s.slots = {}
    return env, ns, s
end

T.test("#17: bars preflight item data before mutating any slot", function()
    local env, ns, s = bars()
    T.equal(env.PickupItem, nil)
    ns.ActionBarsManager:Load()
    T.equal(#s.placements, 0)
    s:resolveItem(99, "Item")
    T.equal(#s.placements, 2)
    T.equal(s.slots[2][2], 99)
    T.equal(s.slots[1][2], 42)
end)

T.test("#17: item failure leaves the whole bar layout unchanged", function()
    local _, ns, s = bars()
    ns.ActionBarsManager:Load()
    s:resolveItem(99, nil, false)
    T.equal(#s.pickups, 0)
    T.equal(#s.placements, 0)
    T.contains(s.output[#s.output], "Could not load item data")
end)

T.test("#17: delayed bar restore rechecks combat and specialization", function()
    for _, change in ipairs({ "combat", "spec" }) do
        local _, ns, s = bars()
        ns.ActionBarsManager:Load()
        if change == "combat" then s.combat = true else s.spec = 2 end
        s:resolveItem(99, "Item")
        T.equal(#s.placements, 0)
        T.contains(s.output[#s.output], "restore cancelled")
    end
end)

T.test("#17: clearing or replacing a snapshot supersedes pending bar restoration", function()
    for _, operation in ipairs({ "Clear", "Save" }) do
        local _, ns, s = bars()
        ns.ActionBarsManager:Load()
        ns.ActionBarsManager[operation](ns.ActionBarsManager)
        s:resolveItem(99, "Item")
        T.equal(#s.placements, 0)
    end
end)

T.test("#17: newer macro requests supersede old content and recheck combat", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    ns.MacroManager:EnsureMacroExists(macro)
    ns.MacroManager:EnsureMacroExists({ name = "item", icon = 123, body = "/say new %item:99%" })
    s:resolveItem(99, "Item")
    T.equal(#s.created, 1)
    T.equal(s.created[1][3], "/say new Item")
    ns.MacroManager:EnsureMacroExists({ name = "other", icon = 123, body = "/use %item:100%" })
    s.combat = true
    s:resolveItem(100, "Other item")
    T.equal(#s.created, 1)
end)

T.test("#17: throwing item requests report failure without mutation", function()
    local env, ns, s, load = fixture(T)
    env.C_Item.RequestLoadItemDataByID = function() error("Unavailable") end
    load("MacroManager.lua")
    ns.MacroManager:EnsureMacroExists(macro)
    T.equal(#s.created, 0)
    T.contains(s.output[#s.output], "Could not load item data")
end)
