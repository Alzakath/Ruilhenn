local T, fixture = ...

local function noLegacyGlobals(env)
    T.equal(env.GetSpecialization, nil, "deprecated specialization wrapper present")
    T.equal(env.GetSpecializationInfo, nil, "deprecated spec-info wrapper present")
    T.equal(env.GetActionText, nil, "deprecated action-text wrapper present")
end

T.test("#14: spell and macro bars round-trip without deprecated API wrappers", function()
    local env, ns, s, load = fixture(T)
    noLegacyGlobals(env)
    s.spec = 2
    s.spells[42] = "Spell"
    s.macros[121] = { name = "Utility", body = "/say test" }
    s.slots[1], s.slots[3] = { "spell", 42 }, { "macro", 121 }
    load("ActionBarsManager.lua")
    ns.ActionBarsManager:Save()
    T.equal(env.RuilhennDB.actionBars.DRUID[2][1][3].id, "Utility")
    T.equal(env.RuilhennDB.actionBars.DRUID[1], nil)
    -- Macro indices may differ when restoring onto another character.
    s.macros[130], s.macros[121] = s.macros[121], nil
    s.slots = {}
    ns.ActionBarsManager:Load()
    T.equal(s.slots[1][2], 42)
    T.equal(s.slots[3][1], "macro")
    T.equal(s.slots[3][2], "Utility")
    T.equal(#s.placements, 2)
end)

T.test("#14: macro action text may be unavailable without breaking snapshots", function()
    local env, ns, s, load = fixture(T)
    noLegacyGlobals(env)
    env.C_ActionBar.GetActionText = function() return nil end
    s.macros[121] = { name = "Utility", body = "/say test" }
    s.slots[1] = { "macro", 121 }
    load("ActionBarsManager.lua")
    ns.ActionBarsManager:Save()
    T.equal(env.RuilhennDB.actionBars.DRUID[1][1][1].type, nil)
    T.contains(table.concat(s.output, "\n"), "Macro not found")
end)

T.test("#14: talent save/load uses namespaced spec index and spec ID contracts", function()
    local talentFixture = dofile("tests/TalentFixture.lua")
    local env, ns, s = talentFixture(T, fixture)
    noLegacyGlobals(env)
    s.spec, s.specID = 2, 103
    s.configIDs[103] = { 10 }
    local text = s:encode({ spec = 103 })
    s.exports[10] = text
    ns.TalentManager:Save()
    T.equal(env.RuilhennDB.talents.DRUID[2][1].importString, text)
    T.equal(env.RuilhennDB.talents.DRUID[1], nil)
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
    T.equal(s.imports[1][1], 10)
    T.equal(s.imports[1][3], "Raid")
    T.equal(s.imports[1][4], text)
end)
