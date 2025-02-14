local _, ns = ...
local MacroTemplates = ns.MacroTemplates

MacroTemplates["WARLOCK"] = function()
    return {
        {
            name = "rain-of-fire",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:5740%
/stopcasting
/cancelqueuedspell
/cast [@cursor] %spell:5740%
        ]]
        },

    }
end
