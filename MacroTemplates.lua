MacroTemplates = {
    DRUID = {
        { 
            name = "crowd-affix", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip [known:Remove Corruption] Remove Corruption; [known:Hibernate] Hibernate
/cast [known:Remove Corruption,target=mouseover,exists,help] Remove Corruption; [known:Hibernate,target=mouseover,exists,harm] Hibernate
            ]] 
        },

        { 
            name = "moonfire", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip Moonfire
/cast [target=mouseover,exists,harm] Moonfire
            ]] 
        },

        { 
            name = "motw", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip
/cast [@player] Mark of the Wild
            ]] 
        },

        { 
            name = "regrowth", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip [known:372119] Regrowth
/cast [target=mouseover,known:372119] Regrowth
            ]] 
        },

        { 
            name = "resurrection", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip [combat] Rebirth; [nocombat] Revive;
/cast [target=mouseover,help,combat,dead][help,combat,dead]Rebirth
/cast [target=mouseover,help,nocombat,dead][help,nocombat,dead]Revive
            ]] 
        },

        { 
            name = "soothe", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip Soothe
/cast [target=mouseover,exists,harm] Soothe
            ]] 
        },

        { 
            name = "ursols-vortex", 
            icon = "INV_Misc_QuestionMark", 
            body = [[
#showtooltip Ursol's Vortex
/cast [@cursor] Ursol's Vortex
            ]] 
        },
    },
}