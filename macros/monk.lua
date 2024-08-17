MacroTemplates["MONK"] = function()
    return {
        {
            name = "detox",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:218164%
/cast [target=mouseover,exists,help] %spell:218164%
        ]]
        },

        {
            name = "paralysis",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:115078%
/cast [target=mouseover,exists,harm] %spell:115078%
        ]]
        },

        {
            name = "jadefire-stomp",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cancelqueuedspell
/cast %spell:388193%
        ]]
        },

        {
            name = "revival",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cancelqueuedspell
/cast %spell:115310%
        ]]
        },

        {
            name = "chi-ji",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cancelqueuedspell
/cast %spell:325197%
        ]]
        },

        {
            name = "ring-of-peace",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cast [@cursor] %spell:116844%
        ]]
        },

        {
            name = "sheiluns-gift",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cancelqueuedspell
/cast %spell:399491%
        ]]
        },

    }
end
