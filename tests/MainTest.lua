local T, fixture = ...

local function boot(locale)
    local env, ns, s, load = fixture(T, locale)
    for line in io.lines("Ruilhenn.toc") do
        local path = line:gsub("\r", ""):match("^%s*(.-)%s*$")
        if path ~= "" and path:sub(1, 1) ~= "#" then
            assert(not path:find("tests", 1, true), "test files must not load in-game")
            load(path:gsub("\\", "/"))
        end
    end
    local frame = env.RuilhennFrame
    assert(frame and frame.scripts.OnEvent, "addon event handler was not loaded")
    local function event(name, ...)
        assert(frame.events[name], "event was not registered")
        frame.scripts.OnEvent(frame, name, ...)
    end
    return env, ns, s, event
end

T.test("Main: TOC load order and ADDON_LOADED initialize only this addon", function()
    local env, ns, s, event = boot()
    -- WoW supplies persisted SavedVariables after file loading, before ADDON_LOADED.
    env.RuilhennDB = { playerSettings = { TestPlayer = { debugMode = true } } }
    event("ADDON_LOADED", "OtherAddon")
    T.equal(#s.output, 0)
    event("ADDON_LOADED", "Ruilhenn")
    T.equal(ns.Config.debugMode, true)
    assert(type(env.SlashCmdList.RUILHENN) == "function")
    for _, command in ipairs({ "bars", "bindings", "macro", "talents", "debug", "help" }) do
        assert(type(env.RuilhennFrame.command[command]) == "function", "missing command " .. command)
    end
    T.equal(env.SLASH_RUILHENN1, "/ruil")
    T.equal(env.SLASH_RUILHENN2, "/ruilhenn")
end)

T.test("Main: slash binding commands save and restore actual API return positions", function()
    local env, _, s, event = boot()
    event("ADDON_LOADED", "Ruilhenn")
    s.bindingRows = { { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" } }
    env.SlashCmdList.RUILHENN("  BINDINGS\tSAVE  ")
    env.SlashCmdList.RUILHENN("bindings load")
    T.equal(#s.assignments, 2)
    T.equal(s.assignments[1][1], "SPACE")
    T.equal(s.assignments[2][1], "CTRL-J")
    T.equal(#s.savedBindings, 1)
end)

T.test("Main: command arguments reach the selected action-bar handler", function()
    local env, _, s, event = boot()
    event("ADDON_LOADED", "Ruilhenn")
    s.slots[1], s.slots[13] = { "spell", 42 }, { "spell", 43 }
    env.SlashCmdList.RUILHENN("BARS CLEAR 1")
    T.equal(s.slots[1], nil)
    T.equal(s.slots[13][2], 43)
end)

T.test("Main: debug status is read-only and toggles persist for this player", function()
    local env, ns, _, event = boot()
    event("ADDON_LOADED", "Ruilhenn")
    env.SlashCmdList.RUILHENN("debug status")
    T.equal(ns.Config.debugMode, false)
    T.equal(env.RuilhennDB.playerSettings.TestPlayer, nil)
    env.SlashCmdList.RUILHENN("debug")
    T.equal(ns.Config.debugMode, true)
    T.equal(env.RuilhennDB.playerSettings.TestPlayer.debugMode, true)
    env.SlashCmdList.RUILHENN("debug")
    T.equal(env.RuilhennDB.playerSettings.TestPlayer.debugMode, false)
end)

T.test("Main: unknown and empty commands show deterministic help", function()
    local env, _, s, event = boot()
    event("ADDON_LOADED", "Ruilhenn")
    for _, command in ipairs({ "", " \t", "not-a-command" }) do
        s.output = {}
        env.SlashCmdList.RUILHENN(command)
        T.contains(s.output[1], "Usage: /ruil")
        T.contains(s.output[3], "bars")
        T.contains(s.output[4], "bindings")
        T.equal(#s.assignments, 0)
        T.equal(#s.placements, 0)
    end
end)

T.test("Main: a command exception is contained and diagnosed in debug mode", function()
    local env, ns, s, event = boot()
    event("ADDON_LOADED", "Ruilhenn")
    ns.Config.debugMode = true
    env.RuilhennFrame.command.broken = function() error("command failure") end
    env.SlashCmdList.RUILHENN("broken")
    T.contains(s.output[#s.output], "command failure")
end)

T.test("Main: French locale loads, dispatches and persists settings", function()
    local env, _, s, event = boot("frFR")
    event("ADDON_LOADED", "Ruilhenn")
    T.contains(s.output[1], "chargée")
    env.SlashCmdList.RUILHENN("debug")
    T.equal(env.RuilhennDB.playerSettings.TestPlayer.debugMode, true)
    T.contains(s.output[#s.output], "activé")
end)
