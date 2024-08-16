MacroTemplates["DRUID"] = function()
    return {
        {
            name = "crowd-affix",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [known:2782] %spell:2782%; [known:2637] %spell:2637%
/cast [known:2782,target=mouseover,exists,help] %spell:2782%; [known:2637,target=mouseover,exists,harm] %spell:2637%
        ]]
        },

        {
            name = "moonfire",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:8921%
/cast [target=mouseover,exists,harm] %spell:8921%
        ]]
        },

        {
            name = "motw",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cast [@player] %spell:1126%
        ]]
        },

        {
            name = "regrowth",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [known:372119] %spell:8936%
/cast [target=mouseover,known:372119] %spell:8936%
        ]]
        },

        {
            name = "resurrection",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip [combat] %spell:20484%; [nocombat] %spell:50769%;
/cast [target=mouseover,help,combat,dead][help,combat,dead] %spell:20484%
/cast [target=mouseover,help,nocombat,dead][help,nocombat,dead] %spell:50769%
        ]]
        },

        {
            name = "soothe",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:2908%
/cast [target=mouseover,exists,harm] %spell:2908%
        ]]
        },

        {
            name = "ursols-vortex",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:102793%
/cast [@cursor] %spell:102793%
        ]]
        },
    }
end
