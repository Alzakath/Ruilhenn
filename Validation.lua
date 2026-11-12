local _, ns = ...
local L = ns.L
local required = {
    "GetActionInfo", "PlaceAction", "PickupAction", "ClearCursor", "GetMacroInfo",
    "CreateMacro", "EditMacro", "PickupMacro", "GetBinding", "SetBinding", "SaveBindings",
    "C_SpecializationInfo.GetSpecialization", "C_SpecializationInfo.GetSpecializationInfo",
    "C_ActionBar.GetActionText", "C_Spell.GetSpellName", "C_Spell.PickupSpell",
    "C_Item.GetItemInfo", "C_Item.PickupItem", "C_Item.RequestLoadItemDataByID",
    "C_Traits.GetConfigInfo", "C_Traits.GetNodeInfo", "C_Traits.GenerateImportString",
    "C_ClassTalents.RequestNewConfig", "C_ClassTalents.ImportLoadout", "C_Timer.NewTimer",
}
local function callable(name)
    local value = _G
    for part in name:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

ns.Commands.validate = function()
    local version, build, date, interface = GetBuildInfo()
    local _, class = UnitClass("player")
    local report = {
        version = version, build = build, buildDate = date, interface = interface,
        locale = GetLocale(), class = class, combat = InCombatLockdown(),
        bindingSet = GetCurrentBindingSet(),
        characterMacroLimit = Constants.MacroConsts.MAX_CHARACTER_MACROS,
        apiPresence = {}, missingAPIs = {}, unresolvedTemplateSpells = {},
        featureTests = "not-run-by-diagnostic",
    }
    for _, name in ipairs(required) do
        local present = callable(name)
        report.apiPresence[name] = present
        if not present then report.missingAPIs[#report.missingAPIs + 1] = name end
    end
    if C_CVar and C_CVar.GetCVar then report.deprecationFallbacks = C_CVar.GetCVar("loadDeprecationFallbacks") end
    local generate = ns.MacroTemplates[class]
    local seen = {}
    if generate then
        for _, macro in ipairs(generate()) do
            for id in macro.body:gmatch("%%spell:(%d+)%%") do
                if not seen[id] then
                    seen[id] = true
                    if not callable("C_Spell.GetSpellName") or not C_Spell.GetSpellName(tonumber(id)) then
                        report.unresolvedTemplateSpells[#report.unresolvedTemplateSpells + 1] = id
                    end
                end
            end
        end
    end
    RuilhennDB.validation = report
    ns.Log:Message(L.VALIDATION_BUILD:format(version, build, tostring(interface), report.locale))
    ns.Log:Message(L.VALIDATION_MISSING:format(#report.missingAPIs > 0 and table.concat(report.missingAPIs, ", ") or L.VALIDATION_NONE))
    ns.Log:Message(L.VALIDATION_FALLBACK:format(tostring(report.deprecationFallbacks or "unknown")))
    ns.Log:Message(L.VALIDATION_TEMPLATES:format(#report.unresolvedTemplateSpells > 0 and table.concat(report.unresolvedTemplateSpells, ", ") or L.VALIDATION_NONE))
    ns.Log:Message(L.VALIDATION_SAVED)
end
