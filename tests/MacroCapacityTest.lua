local T, fixture = ...
local macro = { name = "utility", icon = 123, body = "/say updated" }

T.test("#15: all character slots, including 139-150, update without duplicates", function()
    for index = 121, 150 do
        local env, ns, s, load = fixture(T)
        s.macros[index] = { name = "utility", body = "/say old" }
        load("MacroManager.lua")
        T.equal(ns.MacroManager:EnsureMacroExists(macro), true)
        T.equal(#s.created, 0)
        T.equal(s.macros[index].body, macro.body)
        T.equal(env.NUM_CHARACTER_MACROS, nil)
        T.equal(env.FIRST_CHARACTER_MACRO_INDEX, nil)
    end
end)

T.test("#15: macro scan derives its range from client constants", function()
    local env, ns, s, load = fixture(T)
    env.Constants.MacroConsts = { MAX_ACCOUNT_MACROS = 200, MAX_CHARACTER_MACROS = 2 }
    s.macros[202] = { name = "utility" }
    load("MacroManager.lua")
    T.equal(ns.MacroManager:FindCharacterMacro("utility"), 202)
end)

T.test("#15: full storage reports an error but still allows existing macros to update", function()
    local _, ns, s, load = fixture(T)
    for i = 121, 150 do s.macros[i] = { name = "macro" .. i } end
    load("MacroManager.lua")
    T.equal(ns.MacroManager:EnsureMacroExists(macro), false)
    T.equal(#s.created, 0)
    T.contains(s.output[#s.output], "storage is full")
    s.macros[150].name = macro.name
    T.equal(ns.MacroManager:EnsureMacroExists(macro), true)
    T.equal(s.macros[150].body, macro.body)
end)

T.test("#15: rejected macro writes never report success", function()
    for _, operation in ipairs({ "CreateMacro", "EditMacro" }) do
        for _, throws in ipairs({ false, true }) do
            local env, ns, s, load = fixture(T)
            if operation == "EditMacro" then s.macros[150] = { name = macro.name } end
            env[operation] = function()
                if throws then error("Rejected") end
                return nil
            end
            load("MacroManager.lua")
            ns.Config.debugMode = true
            T.equal(ns.MacroManager:EnsureMacroExists(macro), false)
            local text = table.concat(s.output, "\n")
            T.contains(text, "Could not save macro")
            assert(not text:find("created", 1, true) and not text:find("updated.", 1, true))
        end
    end
end)
