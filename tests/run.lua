-- Run from the addon root with Lua 5.1. No external dependencies required.
local T = dofile("tests/TestHarness.lua")
local fixture = dofile("tests/AddonFixture.lua")

T.test("BindingsManager: existing #12 regression suite", function()
    T.load("tests/BindingsManagerTest.lua", T.sandbox(), {})
end)

for _, file in ipairs({ "CoreTest", "ManagersTest", "MainTest", "TalentImportTest", "RetailAPITest" }) do
    assert(loadfile("tests/" .. file .. ".lua"))(T, fixture)
end

local ok = T.run()
-- Explicit opt-in: known defects should fail instead of being hidden or mocked away.
if arg[1] == "--known-issues" then
    local known = dofile("tests/TestHarness.lua")
    assert(loadfile("tests/KnownIssuesTest.lua"))(known, fixture)
    ok = known.run() and ok
end
if not ok then os.exit(1) end
