local T = { cases = {} }

function T.test(name, run)
    table.insert(T.cases, { name = name, run = run })
end

function T.equal(actual, expected, message)
    assert(actual == expected, (message or "values differ") ..
        ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

function T.contains(text, fragment)
    assert(type(text) == "string" and text:find(fragment, 1, true),
        "expected text containing " .. fragment .. ", got " .. tostring(text))
end

function T.sandbox()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.loadfile = function(path)
        local chunk, err = loadfile(path)
        if chunk then setfenv(chunk, env) end
        return chunk, err
    end
    -- Each fixture owns mutable standard-library tables as well as globals.
    for _, name in ipairs({ "table", "math", "string" }) do
        env[name] = {}
        for key, value in pairs(_G[name]) do env[name][key] = value end
    end
    return env
end

function T.load(path, env, ns)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    return chunk("Ruilhenn", ns)
end

function T.run()
    local failed = 0
    for _, case in ipairs(T.cases) do
        local ok, err = xpcall(case.run, debug.traceback)
        if ok then
            print("PASS " .. case.name)
        else
            failed = failed + 1
            io.stderr:write("FAIL " .. case.name .. "\n" .. err .. "\n")
        end
    end
    print(("%d tests: %d passed, %d failed"):format(#T.cases, #T.cases - failed, failed))
    return failed == 0
end

return T
