-- Run from the addon directory: lua tests/BindingsManagerTest.lua
local function check(value, message)
    assert(value, message)
end

local function setup(locale)
    local state = { rows = {}, calls = {}, saved = {}, messages = {}, errors = {} }
    local ns = { BindingsManager = {}, Commands = {}, L = {}, Log = {} }
    function ns.Log:Message(message) table.insert(state.messages, message) end
    function ns.Log:Error(message) table.insert(state.errors, message) end
    function ns.Log:Debug() end
    RuilhennDB = {}
    GetLocale = function() return locale or "enUS" end
    if locale == "frFR" then
        assert(loadfile("l10n/frFR.lua"))("Ruilhenn", ns)
    elseif not locale or locale == "enUS" then
        assert(loadfile("l10n/enUS.lua"))("Ruilhenn", ns)
    end
    GetCurrentBindingSet = function() return state.currentSet or 2 end
    GetNumBindings = function() return #state.rows end
    GetBinding = function(index) return unpack(state.rows[index], 1, 4) end
    InCombatLockdown = function() return state.combat end
    SetBinding = function(key, command)
        table.insert(state.calls, { key, command })
        if state.reject == key then return false end
        if state.noResult == key then return nil end
        return true
    end
    SaveBindings = function(bindingSet) table.insert(state.saved, bindingSet) end
    assert(loadfile("BindingsManager.lua"))("Ruilhenn", ns)
    return ns.BindingsManager, state
end

local manager, state = setup()
state.rows = {
    { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" },
    { "UNBOUND", "MOVEMENT", "", "" },
    { "SECOND_ONLY", "ACTIONBAR", "", "SHIFT-K" },
}
manager:Save()
check(#RuilhennDB.keyBindings == 2, "unbound commands must not be saved")
check(RuilhennDB.keyBindings[1].key1 == "SPACE", "category saved instead of primary key")
check(RuilhennDB.keyBindings[1].key2 == "CTRL-J", "secondary key lost")
check(RuilhennDB.keyBindings[2].key1 == nil, "empty primary key not normalized")
check(RuilhennDB.keyBindings[2].key2 == "SHIFT-K", "secondary-only binding lost")
check(RuilhennDB.keyBindingsVersion == 1, "backup version missing")
state.currentSet = 1
manager:Load()
check(#state.calls == 3, "both keys must be restored")
check(state.calls[1][1] == "SPACE" and state.calls[1][2] == "JUMP", "wrong primary assignment")
check(state.calls[2][1] == "CTRL-J" and state.calls[2][2] == "JUMP", "wrong secondary assignment")
check(state.calls[3][1] == "SHIFT-K", "wrong secondary-only assignment")
check(#state.saved == 1 and state.saved[1] == 2, "saved binding set not preserved")
check(#state.errors == 0 and #state.messages == 2, "successful round trip reported an error")

for _, version in ipairs({ false, 999 }) do
    manager, state = setup()
    RuilhennDB.keyBindings = { { command = "JUMP", key1 = "MOVEMENT", key2 = "SPACE" } }
    RuilhennDB.keyBindingsVersion = version or nil
    manager:Load()
    check(#state.calls == 0 and #state.saved == 0, "incompatible backup modified bindings")
    check(#state.errors == 1 and state.errors[1]:find("/ruil bindings save", 1, true), "missing resave instructions")
end

for _, rejectedKey in ipairs({ "SPACE", "CTRL-J" }) do
    for _, mode in ipairs({ "reject", "noResult" }) do
        manager, state = setup()
        state.rows = { { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" } }
        manager:Save()
        state.messages = {}
        state[mode] = rejectedKey
        manager:Load()
        check(#state.calls == 2, "one failed assignment must not hide the other key's outcome")
        check(#state.saved == 0, "partial restore was persisted")
        check(#state.messages == 0, "partial restore reported success")
        check(#state.errors == 2, "assignment failure and incomplete restore must be reported")
        check(state.errors[1]:find(rejectedKey, 1, true), "failed key missing from error")
        check(state.errors[1]:find("JUMP", 1, true), "failed command missing from error")
    end
end

manager, state = setup()
manager:Load()
check(#state.calls == 0 and #state.saved == 0, "absent backup modified bindings")
manager:Save()
manager:Load()
check(#state.calls == 0 and #state.saved == 1, "empty current-format backup failed")

manager, state = setup()
state.rows = { { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" } }
manager:Save()
state.combat = true
manager:Load()
check(#state.calls == 0 and #state.saved == 0, "combat restore modified bindings")
check(#state.errors == 1, "combat rejection missing")

for _, locale in ipairs({ "enUS", "frFR", "deDE" }) do
    manager, state = setup(locale)
    RuilhennDB.keyBindings = {}
    manager:Load()
    check(state.errors[1]:find("/ruil bindings save", 1, true), "locale missing recovery command")
    state.errors = {}
    state.rows = { { "JUMP", "MOVEMENT", "SPACE", "CTRL-J" } }
    manager:Save()
    state.reject = "CTRL-J"
    manager:Load()
    check(#state.errors == 2 and state.errors[1]:find("CTRL-J", 1, true), "localized failure formatting failed")
end

print("BindingsManager tests passed")
