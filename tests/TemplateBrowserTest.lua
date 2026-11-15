local T, fixture = ...
local function setup(locale, ui)
    local env, ns, s, load = fixture(T, locale)
    for _, path in ipairs({ "ActionBarsManager.lua", "BindingsManager.lua", "ClickCastingManager.lua",
        "TalentManager.lua", "TemplateStore.lua" }) do load(path) end
    if ui then
        dofile("tests/UIFixture.lua")(env)
        load("TemplateBrowser.lua")
    end
    return env, ns, s, load
end

T.test("Templates: independent spec/category sources and scoped binding copies survive another character", function()
    local env, ns, s = setup()
    s.specID, s.player = 104, "GuardianSource"
    s.bindingRows = { { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" } }
    ns.BindingsManager:Save()
    local guardian = env.RuilhennDB.bindingTemplates.DRUID[104]
    s.spec, s.specID, s.player = 2, 103, "FeralSource"
    s.bindingRows = { { "JUMP", "MOVEMENT", "F" } }
    ns.BindingsManager:Save()
    T.equal(guardian.bindings[1].key1, "SPACE")
    T.equal(env.RuilhennDB.bindingTemplates.DRUID[103].bindings[1].key1, "F")
    T.contains(ns.TemplateStore:Source({ class = "DRUID", specID = 104 }, "bindings"), "GuardianSource")
    T.contains(ns.TemplateStore:Source({ class = "DRUID", specID = 103 }, "bindings"), "FeralSource")
    s.spec, s.specID, s.player = 1, 104, "Destination"
    ns.TemplateStore:Execute("Load", { class = "DRUID", specID = 104 }, "bindings")
    T.equal(s.assignments[1][1], "SPACE")
    T.equal(env.RuilhennDB.keyBindings[1].key1, "F")
    T.equal(#s.savedBindings, 1)
end)

T.test("Templates: legacy saves are browsed without invented provenance or data migration", function()
    local env, ns = setup()
    env.RuilhennDB.actionBars = { DRUID = { [1] = { { { type = "spell", id = 42 } } } } }
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "export" } } } }
    env.RuilhennDB.keyBindings, env.RuilhennDB.keyBindingsVersion = {}, 1
    local entries = ns.TemplateStore:Catalog()
    T.equal(#entries, 1)
    T.equal(#ns.TemplateStore:Inspect(entries[1], "talents"), 1)
    T.contains(ns.TemplateStore:Source(entries[1], "bars"), "Unknown")
    T.equal(env.RuilhennDB.templateInfo, nil)
    T.equal(env.RuilhennDB.bindingTemplates, nil)
end)

T.test("Templates: catalog filters foreign classes but retains other specs of the current class", function()
    local env, ns = setup()
    env.CLASS_SORT_ORDER = { "MAGE", "DRUID" }
    env.C_CreatureInfo = { GetClassInfo = function(id)
        return { classFile = id == 1 and "MAGE" or "DRUID", className = id == 1 and "Mage" or "Druid" }
    end }
    env.GetSpecializationInfoForClassID = function(id, index) return id * 100 + index, "Spec" .. index end
    env.C_SpecializationInfo.GetNumSpecializationsForClassID = function() return 2 end
    env.RuilhennDB.actionBars = { MAGE = { [2] = {} }, DRUID = { [2] = {} } }
    env.RuilhennDB.clickCasting = { MAGE = { [102] = {} } }
    env.RuilhennDB.keyBindings = {}
    local entries = ns.TemplateStore:Catalog()
    T.equal(#entries, 2)
    local otherSpec
    for _, entry in ipairs(entries) do
        T.equal(entry.class, "DRUID")
        if entry.specIndex == 2 then otherSpec = entry end
    end
    T.equal(otherSpec.specID, 202)
    T.equal(ns.TemplateStore:Compatible(otherSpec), false)
    T.equal(ns.TemplateStore:Compatible({ class = "MAGE", specID = 102 }), false)
    T.equal(ns.TemplateStore:Compatible({ global = true }), false)
end)

T.test("Templates: incompatible and combat actions never dispatch mutations", function()
    local _, ns, s = setup()
    local calls = 0
    ns.ActionBarsManager.Save = function() calls = calls + 1 end
    ns.ActionBarsManager.Load = function() calls = calls + 1 end
    local entry = { class = "DRUID", specID = 103 }
    T.equal(ns.TemplateStore:Execute("Save", entry, "bars"), false)
    entry.specID, s.combat = 102, true
    T.equal(ns.TemplateStore:Execute("Save", entry, "bars"), false)
    T.equal(ns.TemplateStore:Execute("Load", entry, "bars"), false)
    T.equal(calls, 0)
end)

T.test("Templates: click inspection predicts missing spells without writing or editing the backup", function()
    local env, ns, s = setup()
    s.clickProfile = { { type = 1, actionID = 1044, button = "RightButton", modifiers = 12 } }
    ns.ClickCastingManager:Save()
    s.missingClickSpells[1044] = true
    local entry = ns.TemplateStore:Catalog()[1]
    local rows = ns.TemplateStore:Inspect(entry, "clicks")
    T.equal(rows[1].missing, true)
    T.equal(#s.clickWrites, 0)
    T.equal(env.RuilhennDB.clickCasting.DRUID[102].bindings[1].actionID, 1044)
end)

T.test("Browser: lazy window registers public skin once and skins controls created later", function()
    local env, ns = setup(nil, true)
    local count, styled = 0, {}
    env.EllesmereUI = { RegisterSkin = function(name, callback)
        T.equal(name, "Ruilhenn")
        count = count + 1
        local skin = {}
        for _, key in ipairs({ "Shell", "Panel", "Button", "Tab", "Font", "CloseButton", "ScrollBar", "EditBox" }) do
            skin[key] = function(frame)
                assert(frame)
                if key == "Button" or key == "Tab" then
                    assert(not frame.skinKind or frame.skinKind == key, "EUI button/tab primitives must not overlap")
                    frame.skinKind = key
                end
                if key == "Button" then
                    assert(frame.icon and frame.selectionMarker, "public keepKeys regions must exist before skin setup")
                end
                styled[key] = (styled[key] or 0) + 1
            end
        end
        skin.IsEnabled = function() return true end
        skin.SetTabSelection = function() end
        callback(skin)
    end }
    ns.TemplateBrowser:Initialize()
    ns.TemplateBrowser:Initialize()
    T.equal(count, 1)
    T.equal(ns.TemplateBrowser.frame, nil)
    ns.TemplateBrowser:Show()
    T.equal(ns.TemplateBrowser.frame:IsShown(), true)
    T.equal(styled.Shell, 1)
    assert(styled.Button > 5 and styled.Font > 3 and styled.ScrollBar == 1)
    local arrowButtons = { ns.TemplateBrowser.contentScroll.ScrollBar:GetChildren() }
    T.equal(arrowButtons[1].regions[1]:GetAlpha(), 0)
    T.equal(arrowButtons[2].regions[1]:GetAlpha(), 0)
end)

T.test("Browser: a late skin callback styles an existing window without recreating it", function()
    local env, ns = setup(nil, true)
    local callback
    env.EllesmereUI = { RegisterSkin = function(_, fn) callback = fn end }
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show()
    local frame, shells = ui.frame, 0
    callback({ Shell = function() shells = shells + 1 end, SetTabSelection = function() end })
    T.equal(shells, 1)
    T.equal(ui.frame, frame)
    T.equal(ui.tabs.talents.alpha, 1)
end)

T.test("Browser: enabled EUI styling fades arrow art and preserves the scrollbar thumb", function()
    local env, ns = setup(nil, true)
    local callback, styledScrollBar
    env.EllesmereUI = { RegisterSkin = function(_, fn) callback = fn end }
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show() -- Native scrollbar is registered before the EUI callback arrives.
    callback({ IsEnabled = function() return true end, ScrollBar = function(frame)
        styledScrollBar = frame
    end })
    T.equal(styledScrollBar, ui.contentScroll.ScrollBar)
    local arrowButtons = { styledScrollBar:GetChildren() }
    T.equal(arrowButtons[1]:IsShown(), true)
    for _, arrow in ipairs(arrowButtons) do
        for _, texture in ipairs(arrow.regions) do T.equal(texture:GetAlpha(), 0) end
    end
    T.equal(styledScrollBar.regions[1]:GetAlpha(), 1) -- Keep the native thumb visible.
end)

T.test("Browser: scrollbar arrow fallback is inactive when EUI skinning is disabled", function()
    local env, ns = setup(nil, true)
    local callback
    env.EllesmereUI = { RegisterSkin = function(_, fn) callback = fn end }
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show()
    callback({ IsEnabled = function() return false end, ScrollBar = function() end })
    local scrollBar = ui.contentScroll.ScrollBar
    local arrows = { scrollBar:GetChildren() }
    for _, arrow in ipairs(arrows) do
        for _, texture in ipairs(arrow.regions) do T.equal(texture:GetAlpha(), 1) end
    end
end)

T.test("Browser: specialization changes dismiss confirmation and prevent the old template from loading", function()
    local _, ns, s = setup(nil, true)
    ns.ClickCastingManager:Save()
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show()
    ui.tabs.clicks:Click()
    ui.load:Click()
    s.spec, s.specID = 2, 103
    s:fire("PLAYER_SPECIALIZATION_CHANGED", "player")
    T.equal(ui.pending, nil)
    T.equal(ui.load.enabled, false)
    T.equal(#s.clickWrites, 0)
end)

T.test("Browser: explicit confirmation saves through managers and records provenance", function()
    local env, ns, s = setup(nil, true)
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show()
    ui.tabs.clicks:Click()
    ui.emptySave:Click()
    T.equal(env.RuilhennDB.clickCasting, nil)
    T.equal(ui.confirmation:IsShown(), true)
    ui:Accept()
    T.equal(#env.RuilhennDB.clickCasting.DRUID[102].bindings, 0)
    T.equal(#s.clickWrites, 0)
    T.contains(ui.source:GetText(), "TestPlayer")
end)

T.test("Browser: changed snapshot invalidates confirmation and unscoped legacy loads are refused", function()
    local env, ns, s = setup(nil, true)
    local ui = ns.TemplateBrowser
    s.bindingRows = { { "JUMP", "MOVEMENT", "SPACE" } }
    ns.BindingsManager:Save()
    ui:Initialize()
    ui:Show()
    ui.tabs.bindings:Click()
    ui.load:Click()
    env.RuilhennDB.bindingTemplates.DRUID[102] = { bindings = {}, version = 1 }
    ui:Accept()
    T.equal(#s.assignments, 0)
    T.contains(s.output[#s.output], "changed")
    T.equal(ns.TemplateStore:Execute("Load", { global = true }, "bindings"), false)
    T.equal(#s.assignments, 0)
    -- Original explicit slash functionality is retained outside scoped templates.
    ns.BindingsManager:Load()
    T.equal(s.assignments[1][1], "SPACE")
end)

T.test("Browser: combat event cancels pending confirmation while keeping browsing usable", function()
    local _, ns, s = setup(nil, true)
    local ui = ns.TemplateBrowser
    ui:Initialize()
    ui:Show()
    ui.tabs.clicks:Click()
    ui.emptySave:Click()
    s.combat = true
    s:fire("PLAYER_REGEN_DISABLED")
    T.equal(ui.confirmation:IsShown(), false)
    T.equal(ui.pending, nil)
    T.equal(ui.save.enabled, false)
    T.equal(ui.load.enabled, false)
    T.equal(ui.frame:IsShown(), true)
    ui:Accept()
    T.equal(#s.clickWrites, 0)
end)

T.test("Browser: selected talent export and single-load dispatch preserve asynchronous result ownership", function()
    local env, ns, s = setup("frFR", true)
    env.RuilhennDB.talents = { DRUID = { [1] = {
        { name = "First", importString = "AAA" }, { name = "Second", importString = "BBB" },
    } } }
    local selected
    ns.TalentManager.Load = function(_, index) selected = index end
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.talents:Click()
    ui.rows[2]:Click()
    T.equal(ui.export:GetText(), "BBB")
    T.equal(ui.talentIndex, 2)
    ui.load:Click()
    ui:Accept()
    T.equal(selected, 2)
    T.equal(#s.output, 0)
end)

T.test("Browser: Settings launcher registers once even if Settings appears later", function()
    local env, ns, s = setup(nil, true)
    ns.TemplateBrowser:Initialize()
    local registrations = 0
    env.Settings = {
        RegisterCanvasLayoutCategory = function(_, name) T.equal(name, "Ruilhenn"); return {} end,
        RegisterAddOnCategory = function() registrations = registrations + 1 end,
    }
    s:fire("ADDON_LOADED", "Blizzard_Settings")
    s:fire("ADDON_LOADED", "OtherAddon")
    T.equal(registrations, 1)
end)

T.test("Handoff: overview counts saved empty categories and keeps independent provenance", function()
    local env, ns = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = {} } }
    ns.ClickCastingManager:Save()
    local ui = ns.TemplateBrowser
    ui:Show()
    local rows, saved = ns.TemplateStore:Overview(ui.selected)
    T.equal(saved, 2)
    T.equal(rows[1].saved, true)
    T.equal(rows[1].count, 0)
    T.contains(rows[1].provenance, "Unknown source")
    T.equal(rows[2].saved, false)
    T.equal(rows[2].provenance, nil)
    T.contains(rows[4].provenance, "TestPlayer")
    T.contains(ui.summary:GetText(), "2 of 4")
    T.equal(ui.save:IsShown(), false)
    T.equal(ui.load:IsShown(), false)
    T.equal(ui.sourcePanel:IsShown(), false)
    T.equal(ui.contentScroll.ScrollBar:IsShown(), false)
    T.equal(ui.rows[1].chevron:GetText(), "›")
    T.contains(ui.rows[1].secondary:GetText(), "Source:")
    T.contains(ui.rows[4].secondary:GetText(), "Saved ")
    T.equal(ui.rows[1].action:GetText(), "Saved template contains no entries")
    T.equal(ui.rows[1].input.ruilhennTextRole, "primary")
    T.equal(ui.rows[1].secondary.ruilhennTextRole, "supporting")
    T.equal(ui.detail:IsShown(), false)
    ui.rows[2]:Click()
    T.equal(ui.category, "bars")
    T.equal(ui.empty:IsShown(), true)
end)

T.test("Review R01: click columns reset alignment after Overview and Talents row reuse", function()
    local env, ns, s = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = {
        { name = "One", importString = "A" }, { name = "Two", importString = "B" },
        { name = "Three", importString = "C" }, { name = "Four", importString = "D" },
        { name = "Five", importString = "E" },
    } } }
    for i = 1, 6 do
        s.clickProfile[i] = { type = 3, actionID = 2,
            button = "LeftButton", modifiers = i - 1 }
    end
    ns.ClickCastingManager:Save()
    local ui = ns.TemplateBrowser
    ui:Show()
    T.equal(ui.rows[1].action.justifyH, "RIGHT")
    T.equal(ui.detail:IsShown(), false) -- R03: no generic Overview helper.

    ui.tabs.talents:Click()
    T.equal(ui.rows[1].status.justifyH, "RIGHT")
    ui.tabs.clicks:Click()
    for i = 1, 6 do
        T.equal(ui.rows[i].action:IsShown(), true)
        T.equal(ui.rows[i].icon:IsShown(), true)
        T.equal(ui.rows[i].action.justifyH, "LEFT")
        T.equal(ui.rows[i].status.justifyH, "LEFT")
    end
    ui.contentScroll:SetVerticalScroll(120)
    T.equal(ui.contentScroll.scroll, 120)
    ui.contentScroll:SetVerticalScroll(0)
    ui.tabs.overview:Click()
    ui.tabs.clicks:Click()
    for i = 1, 6 do
        T.equal(ui.rows[i].action.justifyH, "LEFT")
        T.equal(ui.rows[i].status.justifyH, "LEFT")
    end
end)

T.test("Identity: destination uses live localized class metadata while realm and spec remain neutral", function()
    local env, ns, s = setup(nil, true)
    s.player, s.class = "Dineau", "DRUID"
    local ui = ns.TemplateBrowser
    ui:Show()
    T.equal(ui.characterName:GetText(), "Dineau")
    T.equal(ui.characterName.textColor[1], 1)
    T.equal(ui.characterName.textColor[2], 0.49)
    T.contains(ui.characterSpec:GetText(), "|cff")
    T.contains(ui.characterSpec:GetText(), "LocalizedSpec")
    T.equal(ui.characterRealm.textColor[1], 0.61)
    T.equal(ui.characterActive.textColor[1], 0.61)
    s.class = "PALADIN"
    ui:Refresh()
    T.equal(ui.characterName.textColor[1], 0.96)
    env.C_ClassColor.GetClassColor = function() return nil end
    ui:Refresh()
    T.equal(ui.characterName.textColor[1], 0.94)
end)

T.test("Identity: source delimiter isolates escaped name, realm and date; legacy source stays neutral", function()
    local env, ns = setup(nil, true)
    env.RuilhennDB.actionBars = { DRUID = { [1] = {} } }
    env.RuilhennDB.templateInfo = { DRUID = { [102] = { sources = {
        bars = { character = "D|ineau — KirinTor", savedAt = 1794528000 },
    } } } }
    local entry = ns.TemplateStore:Catalog()[1]
    local source = ns.TemplateStore:SourceDetails(entry, "bars")
    T.equal(source.name, "D|ineau")
    T.equal(source.realm, "KirinTor")
    T.equal(source.class, "DRUID")
    local ui = ns.TemplateBrowser
    ui:Show()
    ui:Navigate("bars")
    T.contains(ui.source:GetText(), "|cff")
    T.contains(ui.source:GetText(), "D||ineau")
    T.contains(ui.source:GetText(), " — KirinTor")
    T.contains(ui.sourceSavedAt:GetText(), "2026")
    env.RuilhennDB.templateInfo.DRUID[102].sources.bars.character = " — realm only"
    ui:Refresh()
    T.equal(ui.source:GetText(), " — realm only")
    T.equal(ui.source.textColor[1], 0.94)
    env.RuilhennDB.templateInfo.DRUID[102].sources.bars.character = "Unparsed source"
    ui:Refresh()
    T.equal(ui.source:GetText(), "Unparsed source")
    T.equal(ui.source.textColor[1], 0.94)
end)

T.test("Identity: subdued source blend remains full-opacity for darker class colors", function()
    local env, ns = setup(nil, true)
    env.UnitClass = function() return "Demon Hunter", "DEMONHUNTER" end
    env.RuilhennDB.actionBars = { DEMONHUNTER = { [1] = {} } }
    env.RuilhennDB.templateInfo = { DEMONHUNTER = { [102] = { sources = {
        bars = { character = "Rav — TestRealm", savedAt = 1794528000 },
    } } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ui:Navigate("bars")
    T.contains(ui.source:GetText(), "|cffac72c8Rav|r")
    T.contains(ui.source:GetText(), "|r — TestRealm")
    T.equal(ui.source.textColor[4], nil) -- color is in the full-opacity markup, not font alpha.
end)

T.test("Identity: five monochrome category glyphs share left alignment and live accent through EUI skinning", function()
    local _, ns = setup(nil, true)
    local ui = ns.TemplateBrowser
    ui:Show()
    local white = { 1, 1, 1 }
    local kept = {}
    ui:ApplySkin({
        GetAccentColor = function() return unpack(white) end,
        Button = function(button, keys)
            for _, key in ipairs(keys or {}) do kept[key] = (kept[key] or 0) + 1 end
        end,
        Font = function() end,
        OnLooksChanged = function(callback) ui.identityLooksChanged = callback end,
    })
    for _, key in ipairs({ "overview", "talents", "bars", "bindings", "clicks" }) do
        local tab = ui.tabs[key]
        T.equal(tab.categoryGlyph, key)
        assert(#tab.categoryParts >= 6)
        T.equal(tab.categoryParts[1].rotation ~= nil, true)
        assert(tab.categoryParts[1].point[4] < -60, "category glyph should sit in the shared left icon box")
        T.equal(tab.fontString.justifyH, "LEFT")
        T.equal(tab.categoryParts[1].color[4], 1)
        assert(kept.categoryPart1)
    end
    T.equal(ui.tabs.overview.categoryParts[1].color[1], 1)
    T.equal(ui.tabs.overview.selectionMarker.color[1], 1)
    white = { 0.2, 0.65, 0.9 }
    ui.identityLooksChanged()
    T.equal(ui.tabs.overview.categoryParts[1].color[1], 0.2)
    T.equal(ui.tabs.overview.fontString.textColor[2], 0.65)
    T.equal(ui.tabs.talents.categoryParts[1].color[1], 0.7)
end)

T.test("Hierarchy: talent summaries distinguish all-present, mixed, all-available, inactive and empty", function()
    local env, ns, s = setup()
    local entry = ns.TemplateStore:Catalog()[1]
    env.RuilhennDB.talents = { DRUID = { [1] = {
        { name = "Known", importString = "A" }, { name = "New", importString = "B" },
    } } }
    s.configIDs[102], s.configs[10] = { 10 }, { name = "Known" }
    local rows = ns.TemplateStore:Inspect(entry, "talents")
    T.equal(rows[1].status, "present")
    T.equal(rows[2].status, "available")
    T.equal(ns.TemplateStore:TalentSummary(entry, rows), "2 saved loadouts · 1 already present · 1 available to import")
    s.configIDs[102], s.configs[11] = { 10, 11 }, { name = "New" }
    rows = ns.TemplateStore:Inspect(entry, "talents")
    T.equal(ns.TemplateStore:TalentSummary(entry, rows), "2 saved loadouts · All already on this character")
    s.configIDs[102], s.configs[11] = {}, nil
    rows = ns.TemplateStore:Inspect(entry, "talents")
    T.equal(ns.TemplateStore:TalentSummary(entry, rows), "2 saved loadouts · All available to import")
    s.spec, s.specID = 2, 103
    rows = ns.TemplateStore:Inspect(entry, "talents")
    T.equal(rows[1].status, "unchecked")
    T.equal(ns.TemplateStore:TalentSummary(entry, rows), "2 loadouts")
    T.equal(ns.TemplateStore:TalentSummary(entry, {}), "Saved template contains no entries")
end)

T.test("Hierarchy: overflow controls the native scrollbar visibility", function()
    local env, ns = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = {
        { name = "One", importString = "A" }, { name = "Two", importString = "B" },
        { name = "Three", importString = "C" }, { name = "Four", importString = "D" },
        { name = "Five", importString = "E" },
    } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    T.equal(ui.contentScroll.ScrollBar:IsShown(), false) -- Overview fits 4 rows.
    ui.tabs.talents:Click()
    T.equal(ui.contentChild:GetHeight(), 280)
    T.equal(ui.contentScroll:GetHeight(), 272)
    T.equal(ui.contentScroll.ScrollBar:IsShown(), true)
    ui.tabs.overview:Click()
    T.equal(ui.contentScroll.ScrollBar:IsShown(), false)
end)

T.test("Hierarchy: semantic font roles survive late and changed EUI font styling", function()
    local env, ns = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "A" } } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.overview:Click()
    local accent = { 0.1, 0.8, 0.7 }
    local function fontSkin(font)
        font:SetTextColor(1, 1, 1)
    end
    local skin = {
        Font = fontSkin,
        GetAccentColor = function() return unpack(accent) end,
        OnLooksChanged = function(callback) ui.testLooksChanged = callback end,
    }
    ui:ApplySkin(skin)
    T.equal(ui.characterName.ruilhennTextRole, "primary")
    T.equal(ui.characterName.textColor[1], 1)
    T.equal(ui.rows[1].secondary.ruilhennTextRole, "supporting")
    T.equal(ui.rows[1].secondary.textColor[1], 0.61)
    ui.tabs.talents:Click()
    ui.rows[1]:Click()
    T.equal(ui.talentIndex, 1)
    accent = { 0.25, 0.5, 0.75 }
    ui.testLooksChanged()
    T.equal(ui.tabs.talents.fontString.textColor[1], 0.25)
    T.equal(ui.tabs.talents.fontString.textColor[2], 0.5)
    T.equal(ui.talentIndex, 1)
    T.equal(ui.export:GetText(), "A")
    T.equal(ui.rows[1].input.textColor[1], 0.25)
    T.equal(ui.rows[1].selectionMarker.color[1], 0.25)
    local fallbackEnv, fallbackNS = setup(nil, true)
    fallbackEnv.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "A" } } } }
    fallbackNS.TemplateBrowser:Show()
    fallbackNS.TemplateBrowser.tabs.talents:Click()
    fallbackNS.TemplateBrowser.rows[1]:Click()
    T.equal(fallbackNS.TemplateBrowser.rows[1].input.textColor[1], 0.047)
    T.equal(fallbackNS.TemplateBrowser.rows[1].selectionMarker.color[2], 0.824)
end)

T.test("Handoff: missing snapshots have a first-save action, saved empty clicks warn about replacement", function()
    local env, ns, s = setup(nil, true)
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.clicks:Click()
    T.equal(ui.sourcePanel:IsShown(), false)
    T.equal(ui.load.enabled, false)
    T.equal(ui.save:IsShown(), false)
    T.equal(ui.emptySave:IsShown(), true)
    ui.emptySave:Click()
    T.contains(ui.confirmText:GetText(), "Create a")
    T.equal(env.RuilhennDB.clickCasting, nil)
    ui:Accept()
    T.equal(ui.sourcePanel:IsShown(), true)
    T.equal(ui.emptySave:IsShown(), false)
    T.equal(ui.load.enabled, true)
    T.contains(ui.emptyTitle:GetText(), "contains no entries")
    ui.load:Click()
    T.contains(ui.confirmText:GetText(), "empty profile")
    T.equal(#s.clickWrites, 0)
    ui:Accept()
    T.equal(#s.clickWrites, 1)
    T.equal(#s.clickWrites[1], 0)
end)

T.test("Handoff: structured click rows and summaries share learned-spell status without preview writes", function()
    local env, ns, s = setup(nil, true)
    s.spells[42], s.spells[1044] = "Healing spell", "Blessing of Freedom"
    env.C_Spell.GetSpellTexture = function(id) return id == 42 and 12345 or nil end
    env.GetStringFromModifiers = function(modifiers) return modifiers == 12 and "Ctrl-" or "" end
    s.clickProfile = {
        { type = 1, actionID = 42, button = "LeftButton", modifiers = 0 },
        { type = 1, actionID = 1044, button = "RightButton", modifiers = 12 },
        { type = 3, actionID = 2, button = "Button5", modifiers = 0 },
    }
    ns.ClickCastingManager:Save()
    s.missingClickSpells[1044] = true
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.clicks:Click()
    local rows = ns.TemplateStore:Inspect(ui.selected, "clicks")
    T.equal(rows[1].action, "Healing spell")
    T.equal(rows[1].icon, 12345)
    T.equal(rows[2].input, "Ctrl + Right mouse button")
    T.equal(rows[2].status, "skipped")
    T.equal(rows[3].action, "Open unit menu")
    T.equal(rows[3].input, "Mouse button 5")
    T.equal(ui.rows[1].input:GetText(), "Left mouse button")
    T.equal(ui.rows[1].icon.texture, 12345)
    T.equal(ui.rows[2].status:GetText(), "Not learned — skipped")
    T.contains(ui.summary:GetText(), "2 bindings available · 1 will be skipped")
    T.equal(#s.clickWrites, 0)
    T.equal(#env.RuilhennDB.clickCasting.DRUID[102].bindings, 3)
    ui.load:Click()
    T.contains(ui.confirmText:GetText(), "1 will be skipped")
end)

T.test("Handoff: inactive spec remains browseable with neutral availability and active/selected markers", function()
    local env, ns, s = setup(nil, true)
    s.clickProfile = { { type = 1, actionID = 42, button = "LeftButton", modifiers = 0 } }
    ns.ClickCastingManager:Save()
    s.spec, s.specID = 2, 103
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.templateButtons[1]:Click()
    ui.tabs.clicks:Click()
    T.equal(ui.selected.specID, 102)
    T.equal(ui.templateButtons[1].selectionMarker:IsShown(), true)
    T.contains(ui.templateButtons[2]:GetText(), "Active")
    T.equal(ui.templateButtons[2].selectionMarker:IsShown(), false)
    T.equal(ui.save.enabled, false)
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "Switch specialization")
    T.contains(ui.summary:GetText(), "active specialization")
    T.equal(ui.rows[1].status:GetText(), "Not checked")
    -- A missing category must still display its own empty state alongside the notice.
    ui.tabs.bars:Click()
    T.equal(ui.empty:IsShown(), true)
    T.equal(ui.emptySave:IsShown(), false)
    T.equal(env.RuilhennDB.actionBars, nil)
end)

T.test("Handoff: category changes reset recycled icons, status labels, colors and talent exports", function()
    local env, ns, s = setup(nil, true)
    s.spells[1044] = "Blessing of Freedom"
    s.clickProfile = { { type = 1, actionID = 1044, button = "RightButton", modifiers = 0 } }
    ns.ClickCastingManager:Save()
    s.missingClickSpells[1044] = true
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "ABC" } } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.clicks:Click()
    T.equal(ui.rows[1].icon:IsShown(), true)
    T.equal(ui.rows[1].status:GetText(), "Not learned — skipped")
    ui.tabs.talents:Click()
    T.equal(ui.rows[1].icon:IsShown(), false)
    T.equal(ui.rows[1].icon.texture, nil)
    T.equal(ui.rows[1].status:IsShown(), true)
    T.equal(ui.rows[1].status:GetText(), ns.L.UI_TALENT_AVAILABLE)
    ui.rows[1]:Click()
    T.equal(ui.export:GetText(), "ABC")
    ui.tabs.overview:Click()
    T.equal(ui.export:IsShown(), false)
    T.equal(ui.export:GetText(), "")
    T.equal(ui.talentIndex, nil)
end)

T.test("Handoff: unresolved click spell labels use readable placeholders instead of IDs", function()
    local _, ns, s = setup()
    s.clickProfile = { { type = 1, actionID = 999999, button = "RightButton", modifiers = 0 } }
    ns.ClickCastingManager:Save()
    local entry = ns.TemplateStore:Catalog()[1]
    local row = ns.TemplateStore:Inspect(entry, "clicks")[1]
    T.equal(row.action, "Spell name unavailable")
    assert(not row.text:find("999999", 1, true))
end)

T.test("Browser: staged talents disable Load with a visible reason while browsing remains usable", function()
    local env, ns, s = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "ABC" } } } }
    s.stagedTalents = true
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.talents:Click()
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "client reports staged")
    T.equal(ui.rows[1].input:GetText(), "Build")
    ui.rows[1]:Click()
    T.equal(ui.export:GetText(), "ABC")
end)

T.test("Browser: finishing a restore re-enables individual talent load without manual Refresh", function()
    local env, ns, s = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = {
        { name = "First", importString = "AAA" }, { name = "Second", importString = "BBB" },
    } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ns.TalentManager.restore = {}
    ui.tabs.talents:Click()
    T.equal(ui.load.enabled, false)
    ns.TalentManager:StopRestore()
    T.equal(ui.load.enabled, true)
    T.equal(ui.notice:GetText(), "")
    ui.rows[2]:Click()
    T.equal(ui.talentIndex, 2)
    T.equal(ui.load:GetText(), ns.L.UI_LOAD_ONE)
    T.equal(#s.imports, 0)
    local chosen
    ns.TalentManager.Load = function(_, index) chosen = index end
    ui.load:Click()
    ui:Accept()
    T.equal(chosen, 2)
end)

T.test("Browser: talent row selection refreshes stale button state without bypassing live guards", function()
    local env, ns, s = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "AAA" } } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.talents:Click()
    ui.load:SetEnabled(false)
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, true)
    s.stagedTalents = true
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "client reports staged")
    s.stagedTalents = false
    env.PlayerSpellsFrame = { TalentsFrame = { IsVisible = function() return true end } }
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "close Blizzard")
    env.PlayerSpellsFrame = nil
    s.spec, s.specID = 2, 103
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "Switch specialization")
    T.equal(#s.imports, 0)
end)

T.test("Browser: hidden native parent does not block talents even when its child remains shown", function()
    local env, ns = setup(nil, true)
    env.RuilhennDB.talents = { DRUID = { [1] = { { name = "Build", importString = "AAA" } } } }
    env.PlayerSpellsFrame = env.CreateFrame("Frame")
    env.PlayerSpellsFrame.TalentsFrame = env.CreateFrame("Frame", nil, env.PlayerSpellsFrame)
    env.PlayerSpellsFrame:Hide()
    T.equal(env.PlayerSpellsFrame.TalentsFrame:IsShown(), true)
    T.equal(env.PlayerSpellsFrame.TalentsFrame:IsVisible(), false)
    T.equal(ns.TalentManager:RestoreBlockReason(), nil)
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.talents:Click()
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, true)
    T.equal(ui.notice:GetText(), "")
    env.PlayerSpellsFrame:Show()
    ui.rows[1]:Click()
    T.equal(ui.load.enabled, false)
    T.contains(ui.notice:GetText(), "close Blizzard")
end)

local function bindingMap(rows)
    local map = {}
    for _, row in ipairs(rows or {}) do
        for i = 3, #row do if row[i] and row[i] ~= "" then map[row[i]] = row[1] end end
    end
    return map
end

local function copyBindingRows(rows)
    local out = {}
    for _, row in ipairs(rows) do
        local item = {}
        for i, value in pairs(row) do item[i] = value end
        out[#out + 1] = item
    end
    return out
end

local function equalBindingMap(a, b)
    for key, command in pairs(a) do assert(b[key] == command, "binding differs for " .. key) end
    for key, command in pairs(b) do assert(a[key] == command, "unexpected binding for " .. key) end
end

local function contextualBindingMap(rows, contexts)
    local map = {}
    for _, row in ipairs(rows or {}) do
        local context = contexts[row[1]]
        for i = 3, #row do
            if row[i] and row[i] ~= "" then
                local identity = tostring(context == nil and "<nil>" or context) .. "\001" .. row[i]
                map[identity] = row[1]
            end
        end
    end
    return map
end

T.test("Bindings scope: browser template imports always merge into character set and preserve account/source", function()
    for activeSet = 1, 2 do
        for sourceSet = 1, 2 do
            local env, ns, s = setup()
            s.bindingSets[1] = { { "JUMP", "Movement", "SPACE", "CTRL-J" }, { "MOVEFORWARD", "Movement", "W" } }
            s.bindingSets[2] = { { "JUMP", "Movement", "X" }, { "CHAR_ONLY", "Other", "Y" } }
            s.currentSet = activeSet
            s.bindingRows = copyBindingRows(s.bindingSets[activeSet])
            env.RuilhennDB.bindingTemplates = { DRUID = { [102] = {
                bindings = { { command = "OPEN_ALL_BAGS", key1 = "B", key2 = "SHIFT-B" } },
                version = 1, bindingSet = sourceSet,
            } } }
            local source = env.RuilhennDB.bindingTemplates.DRUID[102]
            local accountBefore = bindingMap(s.bindingSets[1])
            local sourceSetBefore = source.bindingSet
            local sourceKeyBefore = source.bindings[1].key1
            local uiEnv, uiNS, state = setup(nil, true)
            -- Reuse a freshly configured isolated fixture for the browser load.
            uiEnv.RuilhennDB.bindingTemplates = env.RuilhennDB.bindingTemplates
            state.bindingSets = s.bindingSets
            state.bindingRows = copyBindingRows(s.bindingRows)
            state.currentSet = s.currentSet
            local ui = uiNS.TemplateBrowser
            ui:Show()
            ui.tabs.bindings:Click()
            ui.load:Click()
            T.contains(ui.confirmText:GetText(), sourceSet == 1 and "Saved from: Account" or "Saved from: Character")
            T.contains(ui.confirmText:GetText(), "character-specific bindings")
            ui:Accept()
            T.equal(state.currentSet, 2)
            T.equal(state.savedBindings[#state.savedBindings], 2)
            equalBindingMap(accountBefore, bindingMap(state.bindingSets[1]))
            local characterAfter = bindingMap(state.bindingSets[2])
            T.equal(characterAfter.B, "OPEN_ALL_BAGS")
            T.equal(characterAfter["SHIFT-B"], "OPEN_ALL_BAGS")
            T.equal(characterAfter.Y, "CHAR_ONLY")
            T.equal(source.bindingSet, sourceSetBefore)
            T.equal(source.bindings[1].key1, sourceKeyBefore)
            T.equal(state.savedBindings[1], 2)
        end
    end
end)

T.test("Bindings scope: account snapshot preview restores live mode and unsaved bindings without saving", function()
    local _, ns, s = setup()
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE", "CTRL-J", "ALT-J" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" } }
    s.currentSet = 2
    s.bindingRows = { { "JUMP", "Movement", "UNSAVED" }, { "CHAR_ONLY", "Other", "Y" } }
    local before = bindingMap(s.bindingRows)
    local account = bindingMap(s.bindingSets[1])
    local baseline, fingerprint = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(#baseline.bindings, 3)
    assert(fingerprint)
    equalBindingMap(account, bindingMap(s.bindingSets[1]))
    equalBindingMap(before, bindingMap(s.bindingRows))
    T.equal(s.currentSet, 2)
    T.equal(#s.savedBindings, 0)
end)

T.test("Bindings scope: copy preserves same key independently across Retail binding contexts", function()
    local _, ns, s = setup()
    s.commandContexts = { ACTION_A = 0, ACTION_B = 1, CHAR_ACTION = 0, CHAR_OTHER = 1 }
    s.bindingSets[1] = { { "ACTION_A", "General", "Q" }, { "ACTION_B", "Housing", "Q" } }
    s.bindingSets[2] = { { "CHAR_ACTION", "General", "X" }, { "CHAR_OTHER", "Housing", "Y" } }
    s.currentSet = 1
    s.bindingRows = copyBindingRows(s.bindingSets[1])
    local accountBefore = contextualBindingMap(s.bindingSets[1], s.commandContexts)
    local preview, fingerprint = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    assert(preview)
    T.equal(#preview.bindings, 2)
    assert(fingerprint)
    equalBindingMap(accountBefore, contextualBindingMap(s.bindingSets[1], s.commandContexts))
    equalBindingMap(accountBefore, contextualBindingMap(s.bindingRows, s.commandContexts))

    s.currentSet = 1
    s.bindingRows = copyBindingRows(s.bindingSets[1])
    assert(ns.BindingsManager:CopyAccountBindings(fingerprint))
    equalBindingMap(accountBefore, contextualBindingMap(s.bindingSets[1], s.commandContexts))
    equalBindingMap(accountBefore, contextualBindingMap(s.bindingSets[2], s.commandContexts))
    T.equal(s.currentSet, 2)
    T.equal(s.savedBindings[#s.savedBindings], 2)
end)

T.test("Bindings scope: copy account confirmation works without a template and exactly replaces character set", function()
    local env, ns, s = setup(nil, true)
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE", "CTRL-J", "ALT-J" }, { "MOVEFORWARD", "Movement", "W" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" }, { "CHAR_ONLY", "Other", "Y" } }
    s.currentSet = 1
    s.bindingRows = copyBindingRows(s.bindingSets[1])
    env.RuilhennDB.bindingTemplates = nil
    local accountBefore = bindingMap(s.bindingSets[1])
    local characterBefore = bindingMap(s.bindingSets[2])
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.bindings:Click()
    T.equal(ui.copyAccountBindings:IsShown(), true)
    T.equal(ui.copyAccountBindings.enabled, true)
    T.contains(ui.detail:GetText(), "No saved template is needed")
    T.contains(ui.detail:GetText(), "account or character binding mode")
    T.contains(ui.summary:GetText(), "This character only")
    ui.copyAccountBindings:Click()
    T.contains(ui.confirmText:GetText(), "one-time copy")
    T.contains(ui.confirmText:GetText(), "Character-only bindings will be removed")
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    equalBindingMap(characterBefore, bindingMap(s.bindingSets[2]))
    T.equal(s.currentSet, 1)
    ui.confirmCancel:Click()
    equalBindingMap(characterBefore, bindingMap(s.bindingSets[2]))
    T.equal(s.currentSet, 1)

    ui.copyAccountBindings:Click()
    ui:Accept()
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[2]))
    T.equal(s.currentSet, 2)
    T.equal(s.savedBindings[#s.savedBindings], 2)
    T.contains(s.output[#s.output], "Copied")
    T.equal(env.RuilhennDB.keyBindings, nil)
end)

T.test("Bindings scope: native editor, stale account baseline and failed writes are guarded", function()
    local env, ns, s = setup(nil, true)
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" } }
    s.bindingRows = copyBindingRows(s.bindingSets[2])
    env.RuilhennDB.bindingTemplates = { DRUID = { [102] = {
        bindings = { { command = "OPEN_ALL_BAGS", key1 = "B" } }, version = 1, bindingSet = 1,
    } } }
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.bindings:Click()
    env.KeyBindingFrame = env.CreateFrame("Frame")
    ui:Refresh()
    T.equal(ui.copyAccountBindings.enabled, false)
    T.contains(ui.notice:GetText(), "Close Blizzard")
    env.KeyBindingFrame:Hide()
    ui:Refresh()
    ui.copyAccountBindings:Click()
    s.bindingSets[1] = { { "JUMP", "Movement", "CTRL-SPACE" } }
    ui:Accept()
    T.contains(s.output[#s.output], "changed after review")
    T.equal(s.currentSet, 2)
    T.equal(bindingMap(s.bindingSets[2]).X, "JUMP")

    s.currentSet = 1
    s.bindingRows = copyBindingRows(s.bindingSets[1])
    s.rejectBindingKey = "B"
    local accountBefore = bindingMap(s.bindingSets[1])
    local characterBefore = bindingMap(s.bindingSets[2])
    local profile = env.RuilhennDB.bindingTemplates.DRUID[102]
    ns.BindingsManager:Load(profile, 2)
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    equalBindingMap(characterBefore, bindingMap(s.bindingSets[2]))
    T.equal(s.currentSet, 1)
    T.equal(#s.savedBindings, 0)
    T.contains(s.output[#s.output], "previous live bindings were restored")
end)

T.test("Bindings scope: read and persistence failures never report success or alter account bindings", function()
    local env, ns, s = setup(nil, true)
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" }, { "CHAR_ONLY", "Other", "Y" } }
    s.currentSet = 1
    s.bindingRows = copyBindingRows(s.bindingSets[1])
    local accountBefore = bindingMap(s.bindingSets[1])
    env.RuilhennDB.bindingTemplates = { DRUID = { [102] = {
        bindings = { { command = "OPEN_ALL_BAGS", key1 = "B" } }, version = 1, bindingSet = 1,
    } } }

    s.loadBindingFailure = true
    local preview = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(preview, nil)
    T.equal(#s.savedBindings, 0)
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    s.loadBindingFailure = false

    s.saveBindingFailure = true
    ns.BindingsManager:Load(env.RuilhennDB.bindingTemplates.DRUID[102], 2)
    T.equal(#s.savedBindings, 0)
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    T.contains(s.output[#s.output], "did not confirm saving")
end)

T.test("Bindings scope: copy preflight failures preserve live state and both saved sets", function()
    local _, ns, s = setup()
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" }, { "CHAR_ONLY", "Other", "Y" } }
    s.currentSet = 2
    s.bindingRows = copyBindingRows(s.bindingSets[2])
    local accountBefore = bindingMap(s.bindingSets[1])
    local characterBefore = bindingMap(s.bindingSets[2])

    s.getNumBindingsFailure = true
    local snapshot, snapshotError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(snapshot, nil)
    T.equal(snapshotError, ns.L.UI_BINDING_READ_FAILED)
    T.equal(s.currentSet, 2)
    equalBindingMap(characterBefore, bindingMap(s.bindingRows))
    s.getNumBindingsFailure = false

    s.bindingContextReadFailure = true
    local contextSnapshot, contextError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(contextSnapshot, nil)
    T.equal(contextError, ns.L.UI_BINDING_READ_FAILED)
    T.equal(s.currentSet, 2)
    equalBindingMap(characterBefore, bindingMap(s.bindingRows))
    s.bindingContextReadFailure = false

    s.loadBindingFailureSet = 1
    local loadSnapshot, loadError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(loadSnapshot, nil)
    T.equal(loadError, ns.L.UI_BINDING_READ_FAILED)
    T.equal(s.currentSet, 2)
    equalBindingMap(characterBefore, bindingMap(s.bindingRows))
    s.loadBindingFailureSet = nil

    s.bindingReadFailure = true
    s.bindingReadFailureSet = 1
    local readSnapshot, readError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(readSnapshot, nil)
    T.equal(readError, ns.L.UI_BINDING_READ_FAILED)
    T.equal(s.currentSet, 2)
    equalBindingMap(characterBefore, bindingMap(s.bindingRows))
    s.bindingReadFailure = false
    s.bindingReadFailureSet = nil

    s.bindingRows = { { "JUMP", "Movement", "SPACE" }, { "MOVEFORWARD", "Movement", "SPACE" } }
    local duplicateSnapshot, duplicateError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(duplicateSnapshot, nil)
    T.equal(duplicateError, ns.L.UI_BINDING_READ_FAILED)
    T.equal(s.currentSet, 2)
    T.equal(#s.savedBindings, 0)

    s.bindingRows = copyBindingRows(s.bindingSets[2])
    s.loadBindingFailureSet = 2
    local _, restoreError = ns.BindingsManager:ReadBindingSetPreservingLiveState(1)
    T.equal(restoreError, ns.L.UI_BINDING_STATE_RESTORE_FAILED)
    T.equal(s.currentSet, 2)
    equalBindingMap(accountBefore, bindingMap(s.bindingSets[1]))
    equalBindingMap(characterBefore, bindingMap(s.bindingSets[2]))
    T.equal(#s.savedBindings, 0)
end)

T.test("Bindings scope: copy read failure stays actionable without investigation tracing", function()
    local _, ns, s = setup(nil, true)
    s.bindingSets[1] = { { "JUMP", "Movement", "SPACE" } }
    s.bindingSets[2] = { { "JUMP", "Movement", "X" } }
    s.bindingRows = copyBindingRows(s.bindingSets[2])
    s.currentSet = 2
    ns.Config.debugMode = true
    local ui = ns.TemplateBrowser
    ui:Show()
    ui.tabs.bindings:Click()
    s.getNumBindingsFailure = true
    local outputBefore = #s.output
    ui.copyAccountBindings:Click()
    T.contains(ui.notice:GetText(), "Copy was not started")
    T.equal(#s.output, outputBefore)
    T.equal(ui.confirmation, nil)
    T.equal(s.currentSet, 2)
    T.equal(#s.savedBindings, 0)
end)
