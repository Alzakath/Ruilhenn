MacroTemplates["DEMONHUNTER"] = function()
    return {
        {
            name = "crowd-affix",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:217832%
/cast [target=mouseover,exists,harm] %spell:217832%
        ]]
        },

        {
            name = "metamorphosis",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:191427%
/use 13
/cast [@player,nochanneling] %spell:191427%
        ]]
        },

        {
            name = "sigil-of-misery",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cast [@cursor] %spell:207684%
        ]]
        },

        {
            name = "the-hunt",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip
/cast [nochanneling] %spell:370965%
        ]]
        },

        {
            name = "throw-glaive",
            icon = "INV_Misc_QuestionMark",
            body = [[
#showtooltip %spell:185123%
/cast [target=mouseover,harm] %spell:185123%
        ]]
        },
    }
end
