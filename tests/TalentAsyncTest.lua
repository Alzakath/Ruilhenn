local T, fixture = ...
local talentFixture = dofile("tests/TalentFixture.lua")
local function setup()
    local env, ns, s = talentFixture(T, fixture)
    s.configIDs[102] = {}
    s:backup()
    return env, ns, s
end

T.test("Templates: selected talent import requests only the chosen missing loadout", function()
    local env, ns, s = setup()
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load(2)
    T.equal(#s.requests, 0)
    T.equal(#s.imports, 1)
    T.equal(s.imports[1][1], 10) -- native decoding source is the active config
    T.equal(s.imports[1][3], "Dungeon")
    s:completeTalentCreation("Dungeon", 25)
    T.equal(ns.TalentManager.restore, nil)
    T.equal(#env.RuilhennDB.talents.DRUID[1], 2)
end)

T.test("#16: native import creates one loadout at a time and waits for population", function()
    local env, ns, s = setup()
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    T.equal(#s.requests, 0) -- ImportLoadout owns creation; no RequestNewConfig
    T.equal(#s.imports, 1)
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
    s:completeTalentCreation("Raid", 20, false)
    T.equal(#s.imports, 1)
    T.equal(#s.flags, 0)
    s.configs[20].populated = true
    s:fire("TRAIT_CONFIG_UPDATED", 99)
    T.equal(#s.imports, 1)
    s:fire("TRAIT_CONFIG_UPDATED", 20)
    T.equal(s.flags[1][1], 20)
    T.equal(#s.imports, 1)
    s:expireTimers()
    T.equal(#s.imports, 2)
    T.equal(s.imports[2][3], "Dungeon")
    s:completeTalentCreation("Dungeon", 21)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "2 imported, 0 failed")
    s:expireTimers()
    T.equal(#s.imports, 2)
end)

T.test("#16: rejected and throwing native imports fail without a waiter or false completion", function()
    for _, throws in ipairs({ false, true }) do
        local env, ns, s = setup()
        local attempts = 0
        env.C_ClassTalents.ImportLoadout = function()
            attempts = attempts + 1
            if throws then error("Rejected") end
            return false, "Rejected"
        end
        ns.TalentManager:Load()
        T.equal(#s.requests, 0)
        T.equal(#s.flags, 0)
        T.equal(attempts, 1)
        T.equal(ns.TalentManager.restore ~= nil, true)
        s:expireTimers()
        T.equal(attempts, 2)
        s:expireTimers()
        T.equal(attempts, 3)
        T.equal(ns.TalentManager.restore, nil)
        T.equal(#s.timers, 0)
        T.contains(table.concat(s.output, "\n"), "Rejected")
        T.contains(s.output[#s.output], "0 imported, 1 failed")
    end
end)

T.test("Talents: a transient synchronous rejection retries the same build and then completes", function()
    local env, ns, s = setup()
    local nativeImport, attempts = env.C_ClassTalents.ImportLoadout, 0
    env.C_ClassTalents.ImportLoadout = function(...)
        attempts = attempts + 1
        if attempts == 1 then return false, "Transient rejection" end
        return nativeImport(...)
    end
    ns.TalentManager:Load()
    T.equal(attempts, 1)
    T.equal(#s.imports, 0)
    s:expireTimers()
    T.equal(attempts, 2)
    T.equal(#s.imports, 1)
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "1 imported, 0 failed")
end)

T.test("#16: unrelated, stale and duplicate creation events do not advance restoration", function()
    local env, ns, s = setup()
    ns.TalentManager:Load()
    s:fire("TRAIT_CONFIG_CREATED", { ID = 90, name = "Other", type = 1 })
    s:fire("TRAIT_CONFIG_CREATED", { ID = 10, name = "Raid", type = 1 })
    s:fire("TRAIT_CONFIG_CREATED", { ID = 91, name = "Raid", type = 2 })
    T.equal(#s.flags, 0)
    s:completeTalentCreation("Raid", 20)
    s:fire("TRAIT_CONFIG_CREATED", s.configs[20])
    T.equal(#s.imports, 1)
    T.equal(#s.flags, 1)
end)

T.test("#16: combat or spec changes stop further work and ignore late native results", function()
    for _, change in ipairs({ "combat", "spec" }) do
        local _, ns, s = setup()
        ns.TalentManager:Load()
        if change == "combat" then s.combat = true; s:fire("PLAYER_REGEN_DISABLED")
        else s.spec = 2; s:fire("PLAYER_SPECIALIZATION_CHANGED", "player") end
        s:completeTalentCreation("Raid", 20)
        T.equal(#s.imports, 1) -- the already accepted request cannot be recalled
        T.equal(#s.flags, 0)
        T.equal(ns.TalentManager.restore, nil)
        T.contains(s.output[#s.output], "restore stopped")
    end
end)

T.test("#16: timeout cleans up and late callbacks do not reimport an existing name", function()
    local _, ns, s = setup()
    ns.TalentManager:Load()
    local timer = s.timers[1]
    s:expireTimers()
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "Timed out")
    s:completeTalentCreation("Raid", 20)
    T.equal(#s.flags, 0)
    ns.TalentManager:Load()
    timer.callback()
    T.equal(#s.imports, 1)
    T.contains(s.output[#s.output], "1 existing loadouts kept")
end)

T.test("#16: no import completion message is printed before a populated server result", function()
    local _, ns, s = setup()
    ns.TalentManager:Load()
    T.contains(s.output[#s.output], "Waiting for creation")
    local output = table.concat(s.output, "\n")
    assert(not output:find("restore finished", 1, true))
    assert(not output:find("Saved talent loadout", 1, true))
end)

T.test("#16: transient client readiness waits without resubmitting an import", function()
    local _, ns, s = setup()
    s.notReady = true
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    s.notReady = false
    s:expireTimers()
    T.equal(#s.imports, 1)
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
end)

T.test("#16: persistent creation unavailability stops without an API write", function()
    local _, ns, s = setup()
    s.notReady = true
    ns.TalentManager:Load()
    for _ = 1, 40 do s:expireTimers() end
    T.equal(#s.imports, 0)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "still unable to create")
end)

T.test("#16: a failed shared-bar setting reports an existing incomplete loadout and cleans up", function()
    local env, ns, s = setup()
    env.C_ClassTalents.SetUsesSharedActionBars = function() error("Setting restricted") end
    ns.TalentManager:Load()
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(table.concat(s.output, "\n"), "was created, but")
    T.contains(s.output[#s.output], "0 imported, 1 failed")
end)

T.test("#16: combat during a readiness wait prevents the delayed import", function()
    local _, ns, s = setup()
    s.notReady = true
    ns.TalentManager:Load()
    s.combat = true
    s:fire("PLAYER_REGEN_DISABLED")
    s.notReady = false
    s:expireTimers()
    T.equal(#s.imports, 0)
    T.equal(ns.TalentManager.restore, nil)
end)

T.test("Talents: open native editor prevents import without modifying its pending draft", function()
    local env, ns, s = setup()
    env.PlayerSpellsFrame = { TalentsFrame = { IsVisible = function() return true end } }
    s.stagedTalents = true
    T.equal(ns.TalentManager:Load(), false)
    T.equal(#s.imports, 0)
    T.equal(#s.flags, 0)
    T.equal(s.stagedTalents, true)
    T.contains(s.output[#s.output], "close Blizzard")
end)

T.test("Talents: closing the editor does not bypass pending Apply Changes", function()
    local _, ns, s = setup()
    s.stagedTalents = true
    T.equal(ns.TalentManager:Load(), false)
    T.equal(#s.imports, 0)
    T.contains(s.output[#s.output], "client reports staged")
    s.stagedTalents = false
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
end)

T.test("Talents: opening native editor during a batch stops before the next import", function()
    local env, ns, s = setup()
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    env.PlayerSpellsFrame = { TalentsFrame = { IsVisible = function() return true end } }
    s:completeTalentCreation("Raid", 20)
    T.equal(#s.imports, 1)
    T.equal(#s.flags, 0)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "close Blizzard")
end)

T.test("Talents: owned import scratch is rolled back after saving and original active export is preserved", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    local baseline = s:encode({ selections = { {}, false, false, false, false, false } })
    s.exports[10] = baseline
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    s.stagedTalents = true
    s:completeTalentCreation("Raid", 20)
    assert(ns.TalentManager.restore)
    T.equal(s.rollbacks[1], 10)
    T.equal(s.exports[10], baseline)
    T.equal(s.exports[20], env.RuilhennDB.talents.DRUID[1][1].importString)
    T.equal(s.stagedTalents, false)
    T.equal(ns.TalentManager:RestoreBlockReason(), ns.L.TALENT_RESTORE_BUSY)
    s:expireTimers()
    T.equal(s.stagedTalents, true) -- the second accepted request now owns its scratch
    T.equal(#s.imports, 2)
    s:completeTalentCreation("Dungeon", 21)
    T.equal(ns.TalentManager.restore, nil)
    T.equal(s.stagedTalents, false)
    T.contains(s.output[#s.output], "2 imported, 0 failed")
end)

T.test("Talents: unrelated staged export is not rolled back and yields client diagnostics", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    s.stagedTalents = true
    s.activeStagedExport = s:encode({ selections = { {}, false, false, false, false, false } })
    s:completeTalentCreation("Raid", 20)
    for _ = 1, 40 do s:expireTimers() end
    T.equal(ns.TalentManager.restore, nil)
    T.equal(#s.imports, 1)
    T.equal(s.stagedTalents, true)
    T.equal(s.rollbacks, nil)
    T.contains(table.concat(s.output, "\n"), "staged=true; native talent editor open=false")
    T.contains(table.concat(s.output, "\n"), "Last imported saved config=20")
    ns.Commands.talents("status")
    T.equal(#s.imports, 1)
end)

T.test("Talents: a final populated loadout also cleans up its owned import scratch", function()
    local _, ns, s = setup()
    s.stageOnImport = true
    ns.TalentManager:Load()
    s.stagedTalents = true
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(s.output[#s.output], "1 imported, 0 failed")
    T.equal(s.stagedTalents, false)
    T.equal(s.rollbacks[1], 10)
end)

T.test("Talents: rejected owned-scratch rollback stops without another import", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    ns.TalentManager:Load()
    s.stagedTalents, s.rejectRollback = true, true
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.equal(#s.imports, 1)
    T.equal(s.stagedTalents, true)
    T.equal(s.rollbacks[1], 10)
    T.contains(table.concat(s.output, "\n"), "could not be verified")
end)

T.test("Talents: saved-result export mismatch after rollback cannot report success", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    ns.TalentManager:Load()
    s.stagedTalents = true
    local rollback = env.C_Traits.RollbackConfig
    env.C_Traits.RollbackConfig = function(id)
        rollback(id)
        s.exports[20] = "changed-saved-loadout"
        return true
    end
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    local output = table.concat(s.output, "\n")
    T.contains(output, "could not be verified")
    assert(not output:find("Saved talent loadout:", 1, true))
end)

T.test("Talents: pre-existing drafts never reach import or rollback", function()
    local _, ns, s = setup()
    s.stagedTalents = true
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(s.rollbacks, nil)
    T.equal(s.stagedTalents, true)
end)

T.test("Talents: a missing original active export refuses import before creating scratch", function()
    local _, ns, s = setup()
    s.exports[10] = nil
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(s.rollbacks, nil)
    T.contains(s.output[#s.output], "before import")
end)

T.test("Talents: cleanup must verify the original active export, not just a cleared staged flag", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    ns.TalentManager:Load()
    s.stagedTalents = true
    local rollback = env.C_Traits.RollbackConfig
    env.C_Traits.RollbackConfig = function(id)
        rollback(id)
        s.exports[10] = "wrong-original-active-export"
        return true
    end
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.contains(table.concat(s.output, "\n"), "could not be verified")
end)

T.test("Talents: an imported saved config with its own staged changes prevents cleanup", function()
    local _, ns, s = setup()
    s.stageOnImport = true
    ns.TalentManager:Load()
    s.stagedTalents, s.stagedConfigs = true, { [20] = true }
    s:completeTalentCreation("Raid", 20)
    T.equal(ns.TalentManager.restore, nil)
    T.equal(s.rollbacks, nil)
    T.equal(s.stagedTalents, true)
end)

T.test("Talents: active scratch can differ from the saved export while both are preserved", function()
    local env, ns, s = setup()
    local baseline = s:encode({ selections = { {}, false, false, false, false, false } })
    local scratch = s:encode({ selections = { {}, false, { ranks = 1 }, false, false, false } })
    s.exports[10], s.stageOnImport, s.importScratchExport = baseline, true, scratch
    ns.TalentManager:Load()
    T.equal(s.activeStagedExport, scratch)
    s:completeTalentCreation("Raid", 20)
    T.equal(s.rollbacks[1], 10)
    T.equal(s.exports[10], baseline)
    T.equal(s.exports[20], env.RuilhennDB.talents.DRUID[1][1].importString)
    T.contains(s.output[#s.output], "1 imported, 0 failed")
end)

T.test("Talents: staging appearing only after the import call is not automatically owned", function()
    local _, ns, s = setup()
    ns.TalentManager:Load()
    s.stagedTalents = true
    s:completeTalentCreation("Raid", 20)
    T.equal(s.rollbacks, nil)
    T.equal(s.stagedTalents, true)
    T.contains(s.output[#s.output], "no-synchronous-import-snapshot")
end)

T.test("Talents: synchronous saved-result events wait for the request-boundary snapshot", function()
    local env, ns, s = setup()
    s.stageOnImport = true
    local import = env.C_ClassTalents.ImportLoadout
    env.C_ClassTalents.ImportLoadout = function(...)
        local ok, err = import(...)
        s:completeTalentCreation("Raid", 20)
        return ok, err
    end
    ns.TalentManager:Load()
    T.equal(ns.TalentManager.restore, nil)
    T.equal(#s.imports, 1)
    T.equal(s.rollbacks[1], 10)
    T.contains(s.output[#s.output], "1 imported, 0 failed")
end)

T.test("Talents: the next import never runs inside the previous native config event", function()
    local env, ns, s = setup()
    env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
    local nativeEvent, import = false, env.C_ClassTalents.ImportLoadout
    env.C_ClassTalents.ImportLoadout = function(...)
        assert(not nativeEvent, "native import re-entered during config creation dispatch")
        return import(...)
    end
    ns.TalentManager:Load()
    nativeEvent = true
    s:completeTalentCreation("Raid", 20)
    T.equal(#s.imports, 1)
    nativeEvent = false
    s:expireTimers()
    T.equal(#s.imports, 2)
    nativeEvent = true
    s:completeTalentCreation("Dungeon", 21)
    nativeEvent = false
    T.contains(s.output[#s.output], "2 imported, 0 failed")
end)

T.test("Talents: deferred continuation rechecks combat, spec and native editor", function()
    for _, change in ipairs({ "combat", "spec", "editor" }) do
        local env, ns, s = setup()
        env.RuilhennDB.talents.DRUID[1][2] = { name = "Dungeon", importString = s:encode() }
        ns.TalentManager:Load()
        s:completeTalentCreation("Raid", 20)
        T.equal(#s.imports, 1)
        if change == "combat" then s.combat = true; s:fire("PLAYER_REGEN_DISABLED")
        elseif change == "spec" then s.spec = 2; s:fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        else env.PlayerSpellsFrame = { TalentsFrame = { IsVisible = function() return true end } } end
        s:expireTimers()
        T.equal(#s.imports, 1)
        T.equal(ns.TalentManager.restore, nil)
    end
end)
