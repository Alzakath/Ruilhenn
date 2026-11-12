local T, fixture = ...

T.test("#19: production logger supports event-manager debug toggles", function()
    local _, ns, _, load = fixture(T)
    load("TaskQueue.lua")
    load("EventManager.lua")
    local manager = ns.EventManager:New()
    manager:SetDebugMode(false)
    T.equal(manager.debugMode, false)
    manager:SetDebugMode(true)
    T.equal(manager.debugMode, true)
end)

T.test("#19: stock Lua 5.1 event delivery preserves nil payload positions", function()
    local env, ns, s, load = fixture(T)
    T.equal(env.table.unpack, nil)
    load("TaskQueue.lua")
    load("EventManager.lua")
    local manager, received, count = ns.EventManager:New(), nil, nil
    manager:RegisterEvent("READY", function(...)
        count = select("#", ...)
        received = { ... }
    end)
    manager:FireEvent("READY", nil, "payload", nil)
    s:drain()
    T.equal(count, 3)
    T.equal(received[1], nil)
    T.equal(received[2], "payload")
    T.equal(received[3], nil)
end)

T.test("#19: diagnostics record observations without changing user configuration", function()
    local talentFixture = dofile("tests/TalentFixture.lua")
    local env, ns, s, load = talentFixture(T, fixture)
    local bindings = { { command = "JUMP", key1 = "SPACE" } }
    env.RuilhennDB.keyBindings = bindings
    env.C_CVar = { GetCVar = function() return "0" end }
    ns.MacroTemplates.DRUID = function()
        return { { body = "/cast %spell:42%\n/cast %spell:99%\n/cast %spell:99%" } }
    end
    s.spells[42] = "Spell"
    load("Validation.lua")
    ns.Commands.validate()
    local report = env.RuilhennDB.validation
    T.equal(report.version, "12.1.5")
    T.equal(report.build, "70783")
    T.equal(report.interface, 120105)
    T.equal(report.bindingSet, 2)
    T.equal(report.characterMacroLimit, 30)
    T.equal(report.deprecationFallbacks, "0")
    T.equal(report.featureTests, "not-run-by-diagnostic")
    T.equal(#report.missingAPIs, 0)
    T.equal(#report.unresolvedTemplateSpells, 1)
    T.equal(report.unresolvedTemplateSpells[1], "99")
    T.equal(env.RuilhennDB.keyBindings, bindings)
    T.equal(#s.assignments + #s.created + #s.placements + #s.requests, 0)
end)

T.test("#19: diagnostics identify missing APIs without invoking them", function()
    local env, ns, _, load = fixture(T)
    env.C_Spell.GetSpellName = nil
    env.C_ClassTalents.ImportLoadout = nil
    ns.MacroTemplates.DRUID = function() return { { body = "%spell:42%" } } end
    load("Validation.lua")
    ns.Commands.validate()
    local report = env.RuilhennDB.validation
    T.equal(report.apiPresence["C_ClassTalents.ImportLoadout"], false)
    T.equal(report.apiPresence["C_Spell.GetSpellName"], false)
    T.equal(report.unresolvedTemplateSpells[1], "42")
end)
