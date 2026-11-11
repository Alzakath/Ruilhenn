local T, fixture = ...
local talentFixture = dofile("tests/TalentFixture.lua")

T.test("#13: import preserves argument order and decoded class/spec/hero selections", function()
    local _, ns, s = talentFixture(T, fixture)
    local text = s:encode()
    s:backup(text)
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
    local call = s.imports[1]
    T.equal(call[1], 10)
    T.equal(call[3], "Raid")
    T.equal(call[4], text)
    local entries = call[2]
    T.equal(#entries, 6)
    T.equal(entries[1].nodeID, 10)
    T.equal(entries[1].ranksGranted, 1)
    T.equal(entries[1].ranksPurchased, 0)
    T.equal(entries[2].selectionEntryID, 202)
    T.equal(entries[3].ranksPurchased, 2)
    T.equal(entries[4].selectionEntryID, 402)
    T.equal(entries[5].selectionEntryID, 501)
    T.equal(entries[5].ranksPurchased, 1)
    T.equal(entries[6].selectionEntryID, 502)
    T.equal(entries[6].ranksPurchased, 1)
    T.equal(s.flags[1][2], false)
end)

T.test("#13: exported strings round-trip through saved variables into import entries", function()
    local env, ns, s = talentFixture(T, fixture)
    local text = s:encode()
    s.exports[10] = text
    ns.TalentManager:Save()
    T.equal(env.RuilhennDB.talents.DRUID[1][1].importString, text)
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
    T.equal(s.imports[1][2][4].selectionEntryID, 402)
end)

local invalid = {
    { "bad alphabet", function(s) return s:encode() .. "!" end },
    { "empty string", function() return "" end },
    { "short header", function() return "AAA" end },
    { "truncated body", function(s) return s:encode({ truncate = 156 }) end },
    { "wrong version", function(s) return s:encode({ version = 1 }) end },
    { "wrong spec", function(s) return s:encode({ spec = 103 }) end },
    { "changed tree", function(s) local h = {}; for i = 1, 16 do h[i] = 8 end; return s:encode({ hash = h }) end },
    { "invalid choice", function(s) return s:encode({ selections = { false, { choice = 4 } } }) end },
    { "zero purchased ranks", function(s) return s:encode({ selections = { { ranks = 0 } } }) end },
    { "partial flag on a fully ranked node", function(s) return s:encode({ selections = { false, false, { ranks = 3 } } }) end },
    { "too many ranks", function(s) return s:encode({ selections = { false, false, { ranks = 4 } } }) end },
    { "missing choice flag", function(s) return s:encode({ selections = { false, {} } }) end },
    { "trailing data", function(s) return s:encode() .. "A" end },
}
for _, case in ipairs(invalid) do
    local name, make = case[1], case[2]
    T.test("#13: reject " .. name .. " before any loadout mutation", function()
        local _, ns, s = talentFixture(T, fixture)
        s:backup(make(s))
        ns.TalentManager:Load()
        T.equal(#s.imports, 0)
        T.equal(#s.requests, 0)
        T.equal(#s.flags, 0)
        T.contains(s.output[1], "Could not import")
    end)
end

T.test("#13: full ranks and granted tiered nodes produce valid entries", function()
    local _, ns, s = talentFixture(T, fixture)
    local entries = assert(ns.TalentImport:Decode(s:encode({
        selections = { {}, false, {}, false, { granted = true } },
    }), 10, 102))
    T.equal(#entries, 3)
    T.equal(entries[1].ranksPurchased, 1)
    T.equal(entries[2].ranksPurchased, 3)
    T.equal(entries[3].selectionEntryID, 501)
    T.equal(entries[3].ranksGranted, 1)
    T.equal(entries[3].ranksPurchased, 0)
end)

T.test("#13: an empty selection is a valid array rather than fabricated ranks", function()
    local _, ns, s = talentFixture(T, fixture)
    local entries = assert(ns.TalentImport:Decode(s:encode({ selections = {} }), 10, 102))
    T.equal(#entries, 0)
end)

T.test("#13: unavailable config tree rejects an otherwise valid string", function()
    local _, ns, s = talentFixture(T, fixture)
    s:backup()
    s.configs[10].treeIDs = { 9001 }
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(#s.requests, 0)
    T.contains(s.output[1], "not available")
end)

T.test("#13: invalid strings cannot create missing loadouts", function()
    local _, ns, s = talentFixture(T, fixture)
    s.configIDs[102] = {}
    s:backup("not-a-string")
    ns.TalentManager:Load()
    T.equal(#s.requests, 0)
    T.equal(#s.imports, 0)
end)

T.test("#13: preserve API rejection details and do not change shared-bar settings", function()
    local _, ns, s = talentFixture(T, fixture)
    s.importError = "Requires a rest area"
    s:backup()
    ns.TalentManager:Load()
    T.contains(s.output[1], "Requires a rest area")
    T.equal(#s.flags, 0)
end)

T.test("#13: allow Blizzard's zero-hash third-party format", function()
    local _, ns, s = talentFixture(T, fixture)
    local zero = {}; for i = 1, 16 do zero[i] = 0 end
    s:backup(s:encode({ hash = zero }))
    ns.TalentManager:Load()
    T.equal(#s.imports, 1)
end)

T.test("#13: missing node data fails closed instead of silently dropping a talent", function()
    local _, ns, s = talentFixture(T, fixture)
    s:backup()
    s.nodes[40] = nil
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(#s.flags, 0)
end)

T.test("#13: combat import does not touch talents", function()
    local _, ns, s = talentFixture(T, fixture)
    s:backup()
    s.combat = true
    ns.TalentManager:Load()
    T.equal(#s.imports, 0)
    T.equal(#s.requests, 0)
    T.contains(s.output[1], "combat")
end)

T.test("#13: localized decode failure remains visible", function()
    local _, ns, s = talentFixture(T, fixture, "frFR")
    s:backup("bad!")
    ns.TalentManager:Load()
    T.contains(s.output[1], "Impossible d'importer")
    T.contains(s.output[1], "invalide ou incomplète")
end)
