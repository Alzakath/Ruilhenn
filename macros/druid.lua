local _, ns = ...
local MacroTemplates = ns.MacroTemplates

MacroTemplates["DRUID"] = function()
    return {
        {
            name = "crowd-affix",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [known:2782] %spell:2782%; [known:2637] %spell:2637%
/stopcasting
/cancelqueuedspell
/cast [known:2782,target=mouseover,exists,help] %spell:2782%; [known:2637,target=mouseover,exists,harm] %spell:2637%
        ]]
        },

        {
            name = "moonfire",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:8921%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,exists,harm] %spell:8921%
        ]]
        },

        {
            name = "motw",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/stopcasting
/cancelqueuedspell
/cast [@player] %spell:1126%
        ]]
        },

        {
            name = "regrowth",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [known:372119] %spell:8936%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,known:372119] %spell:8936%
        ]]
        },

        {
            name = "resurrection",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [combat] %spell:20484%; [nocombat] %spell:50769%;
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,help,combat,dead][help,combat,dead] %spell:20484%
/cast [target=mouseover,help,nocombat,dead][help,nocombat,dead] %spell:50769%
        ]]
        },

        {
            name = "soothe",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:2908%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,exists,harm] %spell:2908%
        ]]
        },

        {
            name = "ursols-vortex",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:102793%
/stopcasting
/cancelqueuedspell
/cast [@cursor] %spell:102793%
        ]]
        },

        {
            name = "typhoon",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:132469%
/stopcasting
/cancelqueuedspell
/cast %spell:132469%
        ]]
        },

        {
            name = "efflorescence",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:81269%
/stopcasting
/cancelqueuedspell
/cast [@cursor] %spell:81269%
        ]]
        },

        {
            name = "sunfire",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:93402%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,exists,harm] %spell:93402%
        ]]
        },

        {
            name = "decurse",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:88423%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,exists,help] %spell:88423%
        ]]
        },

    }
end
