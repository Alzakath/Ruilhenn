local T, fixture = ...

T.test("Utils: tokenize command whitespace and preserve arguments", function()
    local _, ns = fixture(T)
    local tokens = ns.Utils:SplitWhitespace("  bars\tclear\n7  9 ")
    local command, args = ns.Utils:UnpackFirst(tokens)
    T.equal(command, "bars")
    T.equal(table.concat(args, ","), "clear,7,9")
    local empty, rest = ns.Utils:UnpackFirst(ns.Utils:SplitWhitespace(" \t"))
    T.equal(empty, nil)
    T.equal(#rest, 0)
end)

T.test("Utils: mapping preserves the input and supports an empty list", function()
    local _, ns = fixture(T)
    local input = { 7, 9 }
    T.equal(table.concat(ns.Utils:Map(tostring, input), ","), "7,9")
    T.equal(input[1], 7)
    T.equal(#ns.Utils:Map(tostring, {}), 0)
end)

T.test("Utils: nested diagnostic output includes values without mutation", function()
    local _, ns = fixture(T)
    local input = { spell = { id = 42 }, empty = false }
    local text = ns.Utils:DumpTable(input)
    T.contains(text, "42")
    T.contains(text, "false")
    T.equal(input.spell.id, 42)
end)

T.test("Config: default debug setting is off and other players remain intact", function()
    local env, ns, _, load = fixture(T)
    env.RuilhennDB.playerSettings = { Other = { debugMode = true } }
    load("Config.lua")
    ns.Config:LoadSavedVariables()
    T.equal(ns.Config.debugMode, false)
    ns.Config:SaveSetting("debugMode", true)
    T.equal(env.RuilhennDB.playerSettings.TestPlayer.debugMode, true)
    T.equal(env.RuilhennDB.playerSettings.Other.debugMode, true)
end)

T.test("Config: saved false and true values survive reload", function()
    local env, ns, _, load = fixture(T)
    load("Config.lua")
    env.RuilhennDB.playerSettings = { TestPlayer = { debugMode = true, unrelated = 9 } }
    ns.Config:LoadSavedVariables()
    T.equal(ns.Config.debugMode, true)
    ns.Config:SaveSetting("debugMode", false)
    ns.Config:LoadSavedVariables()
    T.equal(ns.Config.debugMode, false)
    T.equal(env.RuilhennDB.playerSettings.TestPlayer.unrelated, 9)
end)

T.test("Log: debug output is gated while errors and warnings remain visible", function()
    local _, ns, s = fixture(T)
    ns.Log:Debug("hidden")
    T.equal(#s.output, 0)
    ns.Log:Message("ready")
    ns.Log:Error("failed")
    ns.Log:Warning("warning")
    T.equal(#s.output, 3)
    T.contains(s.output[2], "Ruilhenn Error:")
    ns.Config.debugMode = true
    ns.Log:Debug("visible")
    T.contains(s.output[4], "visible")
end)

T.test("Localization: English and French catalogs have matching keys and placeholders", function()
    local _, english = fixture(T, "enUS")
    local _, french = fixture(T, "frFR")
    local function placeholders(text)
        local result = {}
        for kind in text:gmatch("%%[%d%.%-]*([sdf])") do table.insert(result, kind) end
        return table.concat(result, ",")
    end
    for key, text in pairs(english.L) do
        assert(type(french.L[key]) == "string", "missing French key " .. key)
        T.equal(placeholders(french.L[key]), placeholders(text), "placeholder mismatch for " .. key)
    end
    for key in pairs(french.L) do
        assert(english.L[key], "missing English key " .. key)
    end
end)

T.test("TaskQueue: tasks run later in FIFO order within a frame budget", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    s.fps = 20
    local q, result = ns.TaskQueue:New(), {}
    for i = 1, 5 do
        local value = i
        q:AddTask(function() table.insert(result, value) end)
    end
    q:Run()
    T.equal(#result, 0)
    s:tick()
    T.equal(table.concat(result, ","), "1,2")
    s:drain()
    T.equal(table.concat(result, ","), "1,2,3,4,5")
    T.equal(q.taskFrame.scripts.OnUpdate, nil)
end)

T.test("TaskQueue: low frame rate still makes progress and an idle queue can restart", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    s.fps = 1
    local q, count = ns.TaskQueue:New(), 0
    q:Run()
    T.equal(q.taskFrame.scripts.OnUpdate, nil)
    q:AddTask(function() count = count + 1 end)
    q:Run()
    s:tick()
    T.equal(count, 1)
    q:AddTask(function() count = count + 1 end)
    q:Run()
    s:drain()
    T.equal(count, 2)
end)

T.test("TaskQueue: one failing task does not discard following work", function()
    local _, ns, s, load = fixture(T)
    load("TaskQueue.lua")
    local q, completed = ns.TaskQueue:New(), false
    q:AddTask(function() error("fixture failure") end)
    q:AddTask(function() completed = true end)
    q:Run()
    s:drain()
    T.equal(completed, true)
    T.contains(s.output[1], "fixture failure")
    T.equal(#q.tasks, 0)
end)

T.test("EventManager: registrations, singleton and manager isolation", function()
    local _, ns, _, load = fixture(T)
    load("TaskQueue.lua")
    load("EventManager.lua")
    local a = ns.EventManager:GetInstance()
    T.equal(ns.EventManager:GetInstance(), a)
    a:RegisterEvent("READY", function() end)
    a:RegisterEvent("READY", function() end)
    T.equal(a:GetCallbackCount("READY"), 2)
    T.equal(a:GetCallbackCount("MISSING"), 0)
    T.equal(#a:GetRegisteredEvents(), 1)
    T.equal(a:GetRegisteredEvents()[1], "READY")
    T.equal(ns.EventManager:New():GetCallbackCount("READY"), 0)
end)

T.test("EventManager: callbacks receive payloads in order and errors are isolated", function()
    local env, ns, s, load = fixture(T)
    T.equal(env.table.unpack, nil, "fixture must use stock Lua 5.1")
    load("TaskQueue.lua")
    load("EventManager.lua")
    local manager, received = ns.EventManager:New(), {}
    manager:RegisterEvent("READY", function(a, b)
        table.insert(received, a .. b)
        error("callback failure")
    end)
    manager:RegisterEvent("READY", function(a, b) table.insert(received, b .. a) end)
    manager:FireEvent("READY", "a", "b")
    T.equal(#received, 0)
    s:drain()
    T.equal(table.concat(received, ","), "ab,ba")
    manager:FireEvent("UNREGISTERED")
    s:drain()
    T.equal(#received, 2)
end)
