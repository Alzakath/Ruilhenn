MacroTemplates["DEMONHUNTER"] = {
    { 
        name = "crowd-affix", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Imprison
/cast [target=mouseover,exists,harm] Imprison
        ]] 
    },

    { 
        name = "metamorphosis", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Metamorphosis
/use Ashes of the Embersoul
/cast [@player,nochanneling] Metamorphosis
        ]] 
    },

    { 
        name = "sigil-of-misery", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip
/cast [@cursor] Sigil of Misery
        ]] 
    },

    { 
        name = "the-hunt", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip
/cast [nochanneling] The Hunt
        ]] 
    },

    { 
        name = "throw-glaive", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Throw Glaive
/cast [target=mouseover,harm] Throw Glaive
        ]] 
    },
}