local T, fixture = ...
local function setup(locale)
    local env, ns, s, load = fixture(T, locale)
    load("ClickCastingManager.lua")
    return env, ns, s, load
end
local function row(kind, id, button, modifiers)
    return { type = kind, actionID = id, button = button or "LeftButton", modifiers = modifiers or 0 }
end

T.test("#5: missing learned spells are skipped with a warning and remain in the backup", function()
    for _, locale in ipairs({ "enUS", "frFR" }) do
        local env, ns, s = setup(locale)
        s.clickProfile = { row(1, 42), row(1, 1044, "RightButton", 12), row(3, 1, "MiddleButton") }
        ns.ClickCastingManager:Save()
        s.missingClickSpells[1044] = true
        s.clickProfile, s.output = {}, {}
        T.equal(ns.ClickCastingManager:Load(), true)
        T.equal(#s.clickProfile, 2)
        T.equal(s.clickProfile[2].type, 3)
        T.contains(s.output[1], "Warning")
        T.contains(s.output[1], "1044")
        T.equal(#env.RuilhennDB.clickCasting.DRUID[102].bindings, 3)
        T.equal(ns.ClickCastingManager:Status(), true)
        s.missingClickSpells[1044] = nil
        T.equal(ns.ClickCastingManager:Load(), true)
        T.equal(#s.clickProfile, 3)
    end
end)

T.test("#5: all missing spells restore an empty applicable profile without a mismatch", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 1044) }
    ns.ClickCastingManager:Save()
    s.missingClickSpells[1044] = true
    T.equal(ns.ClickCastingManager:Load(), true)
    T.equal(#s.clickProfile, 0)
    T.equal(#env.RuilhennDB.clickCasting.DRUID[102].bindings, 1)
end)

T.test("#5: spellbook check failure does not silently discard bindings or write", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 1044) }
    ns.ClickCastingManager:Save()
    env.C_SpellBook.IsSpellInSpellBook = function() error("read failed") end
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 0)
    env.C_SpellBook = nil
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 0)
end)

T.test("#5: native spell, pet, interaction and none records round-trip with modifiers", function()
    local env, ns, s = setup()
    s.clickProfile = {
        row(1, 42, "LeftButton", 3), row(4, 99, "Button4", 4),
        row(3, 1, "LeftButton"), row(3, 2, "RightButton"), row(0, 0, "MiddleButton"),
    }
    T.equal(ns.ClickCastingManager:Save(), true)
    local saved = env.RuilhennDB.clickCasting.DRUID[102]
    T.equal(saved.version, 1)
    T.equal(saved.bindings[1].modifiers, 3)
    s.clickProfile[1].actionID = 777
    T.equal(saved.bindings[1].actionID, 42)
    s.clickProfile = { row(1, 43, "Button5") }
    s.reorderClicks = true
    T.equal(ns.ClickCastingManager:Load(), true)
    T.equal(#s.clickProfile, 5)
    T.equal(#s.clickWrites, 1)
    T.equal(s.clickWrites[1][1].actionID, 42)
    T.equal(s.clickWrites[1][2].button, "Button4")
    T.equal(saved.bindings[1].actionID, 42)
end)

T.test("#5: profiles are independent by class and stable spec ID", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    s.spec, s.specID, s.clickProfile = 2, 103, { row(1, 43) }
    ns.ClickCastingManager:Save()
    s.class, s.clickProfile = "MONK", { row(1, 44) }
    ns.ClickCastingManager:Save()
    T.equal(env.RuilhennDB.clickCasting.DRUID[102].bindings[1].actionID, 42)
    T.equal(env.RuilhennDB.clickCasting.DRUID[103].bindings[1].actionID, 43)
    T.equal(env.RuilhennDB.clickCasting.MONK[103].bindings[1].actionID, 44)
    s.class, s.spec, s.specID = "DRUID", 1, 102
    ns.ClickCastingManager:Load()
    T.equal(s.clickProfile[1].actionID, 42)
end)

T.test("#5: empty backups are restorable and distinct from missing backups", function()
    local _, ns, s = setup()
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 0)
    T.equal(ns.ClickCastingManager:Save(), true)
    s.clickProfile = { row(1, 42) }
    T.equal(ns.ClickCastingManager:Load(), true)
    T.equal(#s.clickProfile, 0)
end)

T.test("#5: macro IDs remap within account/character scope after index changes", function()
    local env, ns, s = setup()
    s.macros[1] = { name = "SameName", body = "/say account" }
    s.macros[121] = { name = "SameName", body = "/say character" }
    s.clickProfile = { row(2, 1), row(2, 121, "RightButton", 2) }
    ns.ClickCastingManager:Save()
    s.macros[7], s.macros[150] = s.macros[1], s.macros[121]
    s.macros[1], s.macros[121] = nil, nil
    s.clickProfile = {}
    T.equal(ns.ClickCastingManager:Load(), true)
    T.equal(s.clickProfile[1].actionID, 7)
    T.equal(s.clickProfile[2].actionID, 150)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102].bindings[2].actionID, 121)
    T.equal(#s.created + #s.edited, 0)
end)

T.test("#5: duplicate macro names require a unique matching body", function()
    local _, ns, s = setup()
    s.macros[121] = { name = "Utility", body = "/say wanted" }
    s.clickProfile = { row(2, 121) }
    ns.ClickCastingManager:Save()
    s.macros[121], s.macros[149], s.macros[150] = nil,
        { name = "Utility", body = "/say other" }, { name = "Utility", body = "/say wanted" }
    T.equal(ns.ClickCastingManager:Load(), true)
    T.equal(s.clickProfile[1].actionID, 150)
    s.macros[149].body = "/say wanted"
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 1)
end)

T.test("#5: a missing macro aborts the entire profile before writing any binding", function()
    local _, ns, s = setup()
    s.macros[121] = { name = "Utility", body = "/say test" }
    s.clickProfile = { row(1, 42), row(2, 121, "RightButton") }
    ns.ClickCastingManager:Save()
    s.macros[121] = nil
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 0)
    T.contains(s.output[#s.output], "Utility")
end)

T.test("#5: failed reads and unresolved macros preserve an existing backup", function()
    local env, ns, s = setup()
    ns.ClickCastingManager:Save()
    local saved = env.RuilhennDB.clickCasting.DRUID[102]
    s.getClickError = true
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102], saved)
    s.getClickError, s.clickProfile = false, { row(2, 150) }
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102], saved)
end)

T.test("#5: combat and missing spec do not read or write profiles", function()
    local env, ns, s = setup()
    env.C_ClickBindings.GetProfileInfo = function() error("must not read") end
    s.combat = true
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(ns.ClickCastingManager:Load(), false)
    s.combat, s.spec = false, nil
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(env.RuilhennDB.clickCasting, nil)
    T.equal(#s.clickWrites, 0)
end)

T.test("#5: unavailable APIs fail visibly without breaking addon loading", function()
    local env, ns, s = setup()
    env.C_ClickBindings = nil
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(ns.ClickCastingManager:Load(), false)
    T.contains(s.output[#s.output], "unavailable")
end)

local corruptions = {
    function(saved) saved.version = 999 end,
    function(saved) saved.bindings = "bad" end,
    function(saved) saved.bindings[1].type = 99 end,
    function(saved) saved.bindings[1].modifiers = -1 end,
    function(saved) saved.bindings[1].actionID = 0 end,
    function(saved) saved.bindings[1].button = "" end,
    function(saved) saved.bindings[3] = saved.bindings[1] end,
    function(saved) saved.bindings[2] = saved.bindings[1] end,
    function(saved) saved.bindings[1].type = 3; saved.bindings[1].actionID = 9 end,
}
T.test("#5: incompatible, malformed, sparse and duplicate bindings abort before writing", function()
    for _, corrupt in ipairs(corruptions) do
        local env, ns, s = setup()
        s.clickProfile = { row(1, 42) }
        ns.ClickCastingManager:Save()
        corrupt(env.RuilhennDB.clickCasting.DRUID[102])
        T.equal(ns.ClickCastingManager:Load(), false)
        T.equal(#s.clickWrites, 0)
    end
end)

T.test("#5: unbindable spells and pet actions abort before writing", function()
    for _, kind in ipairs({ 1, 4 }) do
        local _, ns, s = setup()
        s.clickProfile = { row(kind, 42) }
        ns.ClickCastingManager:Save()
        s.unbindable[42] = true
        T.equal(ns.ClickCastingManager:Load(), false)
        T.equal(#s.clickWrites, 0)
    end
end)

T.test("#5: blocked and throwing setters never produce a success message", function()
    for _, throws in ipairs({ false, true }) do
        local _, ns, s = setup()
        s.clickProfile = { row(1, 42) }
        ns.ClickCastingManager:Save()
        s.clickProfile = { row(1, 43) }
        s.throwClicks, s.rejectClicks = throws, not throws
        s.output = {}
        T.equal(ns.ClickCastingManager:Load(), false)
        T.equal(s.clickProfile[1].actionID, 43)
        assert(not table.concat(s.output, "\n"):find("Restored and verified", 1, true))
    end
end)

T.test("#5: successful nil-return setter is verified by readback", function()
    local _, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    s.clickProfile = {}
    T.equal(ns.ClickCastingManager:Load(), true)
    T.contains(s.output[#s.output], "Restored and verified 1")
end)

T.test("#5: saved profiles survive a new addon namespace with the same SavedVariables", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    local nextEnv, nextNS, nextState = setup()
    nextEnv.RuilhennDB = env.RuilhennDB
    T.equal(nextNS.ClickCastingManager:Load(), true)
    T.equal(nextState.clickProfile[1].actionID, 42)
end)

T.test("#5: French messages and unknown commands remain usable", function()
    local _, ns, s = setup("frFR")
    ns.Commands.clicks("wrong")
    T.contains(s.output[#s.output], "/ruil clicks [save|load|status]")
    ns.Commands.clicks("save")
    T.contains(s.output[#s.output], "sauvegardés")
end)

T.test("#5: malformed storage roots are rejected without replacing existing data", function()
    for _, value in ipairs({ 7, "invalid", { DRUID = 7 } }) do
        local env, ns, s = setup()
        env.RuilhennDB.clickCasting = value
        T.equal(ns.ClickCastingManager:Load(), false)
        T.equal(ns.ClickCastingManager:Save(), false)
        T.equal(env.RuilhennDB.clickCasting, value)
        T.equal(#s.clickWrites, 0)
    end
end)

T.test("#5: readback failure after a setter call never claims a verified restore", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    local setter = env.C_ClickBindings.SetProfileByInfo
    env.C_ClickBindings.SetProfileByInfo = function(profile)
        setter(profile)
        s.getClickError = true
    end
    s.output = {}
    T.equal(ns.ClickCastingManager:Load(), false)
    assert(not table.concat(s.output, "\n"):find("Restored and verified", 1, true))
end)

T.test("#5: old backups without macro identity cannot bind an unrelated macro index", function()
    local env, ns, s = setup()
    s.macros[121] = { name = "Utility", body = "/say test" }
    s.clickProfile = { row(2, 121) }
    ns.ClickCastingManager:Save()
    env.RuilhennDB.clickCasting.DRUID[102].bindings[1].macro = nil
    s.macros[121] = { name = "Other", body = "/say unrelated" }
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(#s.clickWrites, 0)
end)

T.test("#5: client changes to the requested table cannot create a false readback pass", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    local setter = env.C_ClickBindings.SetProfileByInfo
    env.C_ClickBindings.SetProfileByInfo = function(profile)
        profile[1].actionID = 43
        setter(profile)
    end
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102].bindings[1].actionID, 42)
end)

T.test("#5: an open native editor is left untouched and blocks save/restore", function()
    local env, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    local saved = env.RuilhennDB.clickCasting.DRUID[102]
    local draft = {}
    env.ClickBindingFrame = { IsShown = function() return true end, pendingChanges = true, dataProvider = draft }
    env.C_ClickBindings.GetProfileInfo = function() error("must not read while editing") end
    T.equal(ns.ClickCastingManager:Save(), false)
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102], saved)
    T.equal(env.ClickBindingFrame.pendingChanges, true)
    T.equal(env.ClickBindingFrame.dataProvider, draft)
    T.equal(#s.clickWrites, 0)
    T.contains(s.output[#s.output], "close Blizzard's click-casting window")
end)

T.test("#5: status explains unchanged mismatches and observes later updates without rewriting", function()
    local _, ns, s = setup()
    s.clickProfile = { row(1, 42) }
    ns.ClickCastingManager:Save()
    s.clickProfile, s.rejectClicks = { row(1, 43) }, true
    T.equal(ns.ClickCastingManager:Load(), false)
    T.equal(ns.ClickCastingManager:Status(), false)
    local text = table.concat(s.output, "\n")
    T.contains(text, "profile unchanged")
    T.contains(text, "wanted type=1 action=42; current type=1 action=43")
    T.equal(#s.clickWrites, 1)
    s.clickProfile = { row(1, 42) }
    T.equal(ns.ClickCastingManager:Status(), true)
    T.equal(#s.clickWrites, 1)
    T.contains(s.output[#s.output], "current native profile matches")
end)

T.test("#5: status rejects missing or different-specialization diagnostics", function()
    local _, ns, s = setup()
    T.equal(ns.ClickCastingManager:Status(), false)
    ns.ClickCastingManager:Save()
    ns.ClickCastingManager:Load()
    s.spec, s.specID = 2, 103
    T.equal(ns.ClickCastingManager:Status(), false)
    T.equal(#s.clickWrites, 1)
    T.contains(s.output[#s.output], "Switch back")
end)
