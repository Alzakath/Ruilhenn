local addonName, ns = ...

-- WoW API
local GetLocale = GetLocale

if GetLocale() ~= "frFR" then return end

ns.L = {}
local L = ns.L

L["LOADED"] = "Version %s chargée"
L["LOADED_TIMER"] = "Ruilhenn chargé en %.4f millisecondes"
L["STARTED"] = "/ruil help pour commencer"
L["CLASS_DETECTED"] = "Classe du joueur détectée : %s"
L["MACRO_CREATED"] = "Macro %s créée (spécifique au personnage)."
L["MACRO_UPDATED"] = "Macro %s mise à jour."
L["NO_MACROS_DEFINED"] = "Aucune macro définie pour la classe %s."
L["ERROR_COROUTINE"] = "Erreur dans la coroutine : %s"
L["SETTINGS_FOUND"] = "Préférences chargées pour %s"
L["SETTINGS_NOT_FOUND"] = "Pas de préférence trouvée pour %s"
L["TASKS_PROCESSED"] = "Tâches traitées."
L["TASKS_ERROR"] = "Erreur dans la tâche : %s"
L["COMMAND_DEBUG_HELP"] = "Active/Désactive le mode debug."
L["COMMAND_STATUS_HELP"] = "Affiche le statut du mode debug."
L["COMMAND_INIT_HELP"] = "Crée ou met à jour les macros de classe."
L["DEBUG_ACTIVATED"] = "Mode debug |cff00ff00activé|r"
L["DEBUG_DEACTIVATED"] = "Mode debug |cffff0000désactivé|r"
