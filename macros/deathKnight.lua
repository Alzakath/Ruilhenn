local _, ns = ...
local MacroTemplates = ns.MacroTemplates

MacroTemplates["DEATHKNIGHT"] = function()
    return {
        {
            name = "amz",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/stopcasting
/cancelqueuedspell
/cast [@cursor] %spell:51052%
        ]]
        },

        {
            name = "chain-of-ice",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/stopcasting
/cancelqueuedspell
/cast [@mouseover] %spell:45524%
        ]]
        },

        {
            name = "crowd-affix",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:111673%
/stopcasting
/cancelqueuedspell
/target pet
/script PetDismiss()
/cast %spell:111673%
        ]]
        },

        {
            name = "death-and-decay",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/stopcasting
/cancelqueuedspell
/cast [@cursor] %spell:43265%
        ]]
        },

        {
            name = "death-grip",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:49576%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,harm][harm] %spell:49576%
        ]]
        },

        {
            name = "deaths-caress",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:195292%
/stopcasting
/cancelqueuedspell
/cast [target=mouseover,harm][harm] %spell:195292%
        ]]
        },

        {
            name = "gorefiends-grasp",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [known:108199] %spell:108199%
/stopcasting
/cancelqueuedspell
/cast [@player, known:108199] %spell:108199%
        ]]
        },

        {
            name = "resurrection",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [combat] %spell:61999%; [nocombat] %item:114943%;
/stopcasting
/cancelqueuedspell
/use [target=mouseover,help,combat,dead][help,combat,dead] %spell:61999%; [target=mouseover,help,nocombat,dead][help,nocombat,dead] %item:114943%
        ]]
        },
    }
end
