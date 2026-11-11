local T, fixture = ...

T.test("ActionBars: spells, items and named macros survive a save/load round trip", function()
    local env, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.spells[42], s.items[99] = "Spell", "Item"
    s.macros[121] = { name = "utility", body = "/say test" }
    s.slots[1], s.slots[2], s.slots[3] = { "spell", 42 }, { "item", 99 }, { "macro", 121 }
    ns.ActionBarsManager:Save()
    local saved = env.RuilhennDB.actionBars.DRUID[1]
    T.equal(saved[1][1].id, 42)
    T.equal(saved[1][2].id, 99)
    T.equal(saved[1][3].id, "utility")
    T.equal(saved[1][4].type, nil)
    s.slots = {}
    ns.ActionBarsManager:Load()
    T.equal(s.slots[1][1], "spell")
    T.equal(s.slots[1][2], 42)
    T.equal(s.slots[2][2], 99)
    T.equal(s.slots[3][1], "macro")
    T.equal(s.slots[3][2], "utility")
    T.equal(#s.placements, 3)
end)

T.test("ActionBars: class and specialization snapshots do not overwrite one another", function()
    local env, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1] = { "spell", 42 }
    ns.ActionBarsManager:Save()
    s.spec, s.slots[1] = 2, { "spell", 43 }
    ns.ActionBarsManager:Save()
    s.class = "MONK"
    ns.ActionBarsManager:Save()
    T.equal(env.RuilhennDB.actionBars.DRUID[1][1][1].id, 42)
    T.equal(env.RuilhennDB.actionBars.DRUID[2][1][1].id, 43)
    T.equal(env.RuilhennDB.actionBars.MONK[2][1][1].id, 43)
end)

T.test("ActionBars: invalid slots and missing spells do not place actions", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    for _, slot in ipairs({ 0, 181 }) do
        T.equal(ns.ActionBarsManager:PlaceActionSafely(slot, 42, "spell"), false)
    end
    T.equal(ns.ActionBarsManager:PlaceActionSafely(nil, 42, "spell"), false)
    T.equal(ns.ActionBarsManager:PlaceActionSafely(1, 42, "spell"), false)
    T.equal(#s.pickups, 0)
    T.equal(#s.placements, 0)
    T.equal(s.cursor, nil)
end)

T.test("ActionBars: unavailable macros are not saved as portable actions", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1] = { "macro", 121 }
    T.equal(ns.ActionBarsManager:GetActionBarInfo(1).type, nil)
    T.contains(s.output[#s.output], "Macro not found")
end)

T.test("ActionBars: rejected placement reports failure and releases the cursor", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.spells[42], s.rejectPlacement = "Spell", true
    T.equal(ns.ActionBarsManager:PlaceActionSafely(1, 42, "spell"), false)
    T.equal(s.cursor, nil)
    T.contains(s.output[#s.output], "Failed to place")
end)

T.test("ActionBars: restore in combat and restore without a snapshot do not mutate slots", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    ns.ActionBarsManager:Load()
    s.combat = true
    ns.ActionBarsManager:Load()
    T.equal(#s.placements, 0)
    T.equal(#s.pickups, 0)
    T.contains(s.output[#s.output], "combat")
end)

T.test("ActionBars: clearing a selected bar preserves other bars", function()
    local _, ns, s, load = fixture(T)
    load("ActionBarsManager.lua")
    s.slots[1], s.slots[13] = { "spell", 42 }, { "item", 99 }
    ns.ActionBarsManager:Clear("1")
    T.equal(s.slots[1], nil)
    T.equal(s.slots[13][2], 99)
    T.equal(s.cursor, nil)
    ns.ActionBarsManager:Clear()
    T.equal(s.slots[13], nil)
end)

T.test("Macros: expand repeated localized spell and item placeholders", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    s.spells[42], s.items[99] = "Éclat lunaire", "Objet"
    local text = ns.MacroManager:ReplaceSpellIDs("/cast %spell:42%\n/use %item:99%\n#showtooltip %spell:42%")
    T.equal(text, "/cast Éclat lunaire\n/use Objet\n#showtooltip Éclat lunaire")
    T.equal(ns.MacroManager:ReplaceSpellIDs("/say 100%"), "/say 100%")
end)

T.test("Macros: create character-specific macros then edit instead of duplicating", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    local macro = { name = "utility", icon = 123, body = "/say first" }
    ns.MacroManager:EnsureMacroExists(macro)
    T.equal(#s.created, 1)
    T.equal(s.created[1][4], true)
    macro.body = "/say updated"
    ns.MacroManager:EnsureMacroExists(macro)
    T.equal(#s.created, 1)
    T.equal(#s.edited, 1)
    T.equal(s.macros[121].body, "/say updated")
end)

T.test("Macros: an account macro with the same name is not overwritten", function()
    local _, ns, s, load = fixture(T)
    load("MacroManager.lua")
    s.macros[1] = { name = "utility", body = "/say account" }
    ns.MacroManager:EnsureMacroExists({ name = "utility", icon = 123, body = "/say character" })
    T.equal(s.macros[1].body, "/say account")
    T.equal(s.macros[121].body, "/say character")
end)

T.test("Macros: queued creation rechecks combat before touching macros", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    load("MacroManager.lua")
    ns.MacroTemplates.DRUID = function()
        return { { name = "utility", icon = 123, body = "/say test" } }
    end
    ns.Commands.macro("init")
    T.equal(#s.created, 0)
    s.combat = true
    s:drain()
    T.equal(#s.created, 0)
    T.equal(#s.edited, 0)
    T.contains(s.output[#s.output], "combat")
end)

T.test("Macros: unsupported classes show a warning without scheduling work", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    load("MacroManager.lua")
    ns.Commands.macro("init")
    T.equal(#s.created, 0)
    T.equal(#s.frames, 0)
    T.contains(s.output[#s.output], "No macros defined")
end)

T.test("Talent exports: preserve names, strings, shared-bar flags and other specs", function()
    local env, ns, s, load = fixture(T)
    load("TalentManager.lua")
    s.configIDs[102] = { 10, 11, 12, 13 }
    s.configs[10] = { name = "Raid", usesSharedActionBars = false }
    s.configs[11] = { name = "Dungeon", usesSharedActionBars = true }
    s.configs[12] = { name = "No export" }
    s.exports[10], s.exports[11] = "raid-export", "dungeon-export"
    env.RuilhennDB.talents = { DRUID = { [2] = { "preserved" } } }
    ns.TalentManager:Save()
    local saved = env.RuilhennDB.talents.DRUID[1]
    T.equal(#saved, 2)
    T.equal(saved[1].name, "Raid")
    T.equal(saved[1].importString, "raid-export")
    T.equal(saved[1].usesSharedActionBars, false)
    T.equal(saved[2].usesSharedActionBars, true)
    T.equal(env.RuilhennDB.talents.DRUID[2][1], "preserved")
    T.equal(ns.TalentManager:GetConfigMap(102).Dungeon, 11)
end)

T.test("Talents: no active spec does not create an invalid backup", function()
    local env, ns, s, load = fixture(T)
    load("TalentManager.lua")
    s.spec = nil
    ns.TalentManager:Save()
    T.equal(env.RuilhennDB.talents, nil)
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(#s.requests, 0)
end)

T.test("Talents: missing snapshots and unspent points prevent imports", function()
    for _, field in ipairs({ "none", "unspent", "unspentHero" }) do
        local env, ns, s, load = fixture(T)
        load("TalentManager.lua")
        s[field] = true
        if field ~= "none" then
            env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Raid", importString = "export" } } } }
        end
        ns.TalentManager:Load()
        T.equal(#s.imports, 0)
        T.equal(#s.requests, 0)
        T.contains(s.output[#s.output], field == "none" and "No saved talents" or "unspent")
    end
end)

T.test("Templates: each class generates independent, uniquely named usable records", function()
    local env, ns, s, load = fixture(T)
    -- Metadata/placeholder test only: these names do not certify spell availability.
    env.C_Spell.GetSpellName = function(id) return "Spell" .. id end
    env.C_Item.GetItemInfo = function(id) return "Item" .. id end
    load("MacroManager.lua")
    for _, file in ipairs({ "druid", "demonHunter", "deathKnight", "monk", "warlock" }) do
        load("macros/" .. file .. ".lua")
    end
    local classes = 0
    for _, generate in pairs(ns.MacroTemplates) do
        classes = classes + 1
        local names, templates = {}, generate()
        assert(#templates > 0)
        for _, macro in ipairs(templates) do
            assert(type(macro.name) == "string" and macro.name ~= "" and not names[macro.name])
            names[macro.name] = true
            assert(macro.icon and type(macro.body) == "string" and macro.body ~= "")
            local expanded = ns.MacroManager:ReplaceSpellIDs(macro.body)
            assert(not expanded:find("%%spell:") and not expanded:find("%%item:"))
            assert(not expanded:find("UnknownSpell") and not expanded:find("UnknownItem"))
        end
        templates[1].name = "mutated"
        assert(generate()[1].name ~= "mutated", "template calls share mutable output")
    end
    T.equal(classes, 5)
    T.equal(#s.created, 0)
end)
