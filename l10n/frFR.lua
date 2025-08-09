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
L["KEY_BINDINGS_SAVED"] = "Bindings sauvés."
L["KEY_BINDINGS_LOADED"] = "Bindings chargés."
L["ACTIONBARS_SAVED"] = "Barres d'action sauvées."
L["ACTIONBARS_LOADED"] = "Barres d'action chargées."
L["COMMAND_SAVE_BINDINGS_HELP"] = "Sauver les bindings."
L["COMMAND_LOAD_BINDINGS_HELP"] = "Charger les bindings."
L["COMMAND_SAVE_BARS_HELP"] = "Sauver les barres d'action."
L["COMMAND_LOAD_BARS_HELP"] = "Charger les barres d'action."
L["COMMAND_EMPTY_BARS_HELP"] = "Vider les barres d'action."
L["INVALID_ACTION_SLOT"] = "Emplacement d'action invalide: %s"
L["SPELL_NOT_FOUND"] = "Sort non trouvé: %s"
L["ITEM_NOT_FOUND"] = "Objet non trouvé: %s"
L["MACRO_NOT_FOUND"] = "Macro non trouvée: %s"
L["INVALID_ACTION_TYPE"] = "Type d'action invalide: %s"
L["ACTION_PLACED_SUCCESS"] = "%s (ID: %s) déplacé avec succè dans l'emplacement %s"
L["ACTION_PLACED_FAILED"] = "Echec du déplacement de %s %s (ID: %s) dans l'emplacement %s"
L["ACTION_CLEARED_SUCCESS"] = "Emplacement d'action vidé avec succès %s"
L["ACTION_CLEARED_FAILED"] = "Echec du nettoyage de l'emplacement %s"
L["ACTIONS_CLEARED_COMPLETE"] = "Emplacements d'action %s vidé en %.4f secondes"
L["CLEARING_ACTIONS_START"] = "Début: Nettoyage des emplacements d'action"
L["MOUNT_CANNOT_BE_PLACED"] = "Les montures ne sont pas traitées."
