MacroTemplates["DEATHKNIGHT"] = {
    { 
        name = "amz", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip
/cast [@cursor] Anti-Magic Zone
        ]] 
    },

    { 
        name = "chain-of-ice", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip
/cast [@mouseover] Chains of Ice
        ]] 
    },

    { 
        name = "crowd-affix", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Control Undead
/target pet
/script PetDismiss()
/cast Control Undead
        ]] 
    },

    { 
        name = "death-and-decay", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Death and Decay
/cast [@cursor] Death and Decay
        ]] 
    },

    { 
        name = "death-grip", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Death Grip
/cast [target=mouseover,harm][harm] Death Grip
        ]] 
    },

    { 
        name = "deaths-caress", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip Death's Caress
/cast [target=mouseover,harm][harm] Death's Caress
        ]] 
    },

    { 
        name = "gorefiends-grasp", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip [known:108199] Gorefiend's Grasp
/cast [@player, known:108199] Gorefiend's Grasp
        ]] 
    },

    { 
        name = "resurrection", 
        icon = "INV_Misc_QuestionMark", 
        body = [[
#showtooltip [combat] Raise Ally; [nocombat] Ultimate Gnomish Army Knife;
/use [target=mouseover,help,combat,dead][help,combat,dead] Raise Ally; [target=mouseover,help,nocombat,dead][help,nocombat,dead] Ultimate Gnomish Army Knife 
        ]] 
    },
}