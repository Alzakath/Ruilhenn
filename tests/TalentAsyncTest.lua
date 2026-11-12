local T, fixture = ...
local talentFixture = dofile("tests/TalentFixture.lua")
local function setup()
    local env, ns, s = talentFixture(T, fixture)
    s.configIDs[102] = {}
    s:backup()
    return env, ns, s
end
local function created(env, s, name, id)
    local info = { name = name, ID = id, type = env.Enum.TraitConfigType.Combat, treeIDs = { 9000 } }
    s.configs[id] = info
    table.insert(s.configIDs[102], id)
    s:fire("TRAIT_CONFIG_CREATED", info)
end

T.test("#16: missing loadouts restore serially after matching server events", function()
    local env, ns, s = setup()
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    T.equal(#s.requests, 1)
    T.equal(#s.imports, 0)
    ns.TalentManager:Load()
    T.equal(#s.requests, 1)
    created(env, s, "Raid", 20)
    T.equal(#s.imports, 1)
    T.equal(s.imports[1][1], 20)
    T.equal(#s.requests, 2)
    T.equal(s.requests[2], "Dungeon")
    created(env, s, "Dungeon", 21)
    T.equal(#s.imports, 2)
    T.equal(s.imports[2][1], 21)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "2 imported, 0 failed")
    s:expireTimers()
    T.equal(#s.imports, 2)
end)

T.test("#16: rejected and throwing creation requests fail visibly without waiting", function()
    for _, throws in ipairs({ false, true }) do
        local env, ns, s = setup()
        s.rejectCreation = true
        if throws then env.C_ClassTalents.RequestNewConfig = function() error("Rejected") end end
        ns.TalentManager:Load()
        T.equal(#s.imports, 0)
        T.equal(ns.TalentManager.restore, nil)
        T.equal(#s.timers, 0)
        T.contains(table.concat(s.output, "\n"), "refused to create")
        assert(not table.concat(s.output, "\n"):find("Waiting for creation", 1, true))
    end
end)

T.test("#16: unrelated, stale and duplicate creation events do not advance restoration", function()
    local env, ns, s = setup()
    ns.TalentManager:Load()
    s:fire("TRAIT_CONFIG_CREATED", { ID = 90, name = "Other", type = 1 })
    s:fire("TRAIT_CONFIG_CREATED", { ID = 10, name = "Raid", type = 1 })
    s:fire("TRAIT_CONFIG_CREATED", { ID = 91, name = "Raid", type = 2 })
    T.equal(#s.imports, 0)
    created(env, s, "Raid", 20)
    s:fire("TRAIT_CONFIG_CREATED", s.configs[20])
    T.equal(#s.imports, 1)
end)

T.test("#16: combat or spec changes cancel a pending restore before import", function()
    for _, change in ipairs({ "combat", "spec" }) do
        local env, ns, s = setup()
        ns.TalentManager:Load()
        if change == "combat" then
            s.combat = true
            s:fire("PLAYER_REGEN_DISABLED")
        else
            s.spec = 2
            s:fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        end
        created(env, s, "Raid", 20)
        T.equal(#s.imports, 0)
        T.equal(ns.TalentManager.restore, nil)
        T.contains(s.output[#s.output], "restore stopped")
    end
end)

T.test("#16: timeout cleans up and late callbacks cannot mutate a cancelled restore", function()
    local env, ns, s = setup()
    ns.TalentManager:Load()
    local timer = s.timers[1]
    s:expireTimers()
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "Timed out")
    created(env, s, "Raid", 20)
    T.equal(#s.imports, 0)
    ns.TalentManager:Load()
    timer.callback()
    T.equal(#s.imports, 1)
end)

T.test("#16: no completion message is printed before a server response", function()
    local _, ns, s = setup()
    ns.TalentManager:Load()
    T.contains(s.output[#s.output], "Waiting for creation")
    assert(not table.concat(s.output, "\n"):find("restore finished", 1, true))
end)
