local addonName, ns = ...

-- WoW API
local GetLocale = GetLocale

if GetLocale() ~= "frFR" then return end

ns.L = {}
local L = ns.L

L["LOADED"] = "Version %s chargée"
L["LOADED_TIMER"] = "Ruilhenn a mis %.4f millisecondes à charger"
L["STARTED"] = "/ruil help pour commencer"
L["CLASS_DETECTED"] = "Classe du joueur détectée : %s"
L["MACRO_CREATED"] = "Macro %s créée (spécifique au personnage)."
L["MACRO_UPDATED"] = "Macro %s mise à jour."
L["NO_MACROS_DEFINED"] = "Aucune macro définie pour la classe %s."
L["ERROR_COROUTINE"] = "Erreur dans la coroutine : %s"
L["SETTINGS_FOUND"] = "Paramètres chargés pour %s"
L["SETTINGS_NOT_FOUND"] = "Aucun paramètre trouvé pour %s"
L["TASKS_PROCESSED"] = "Toutes les tâches ont été traitées."
L["TASKS_ERROR"] = "Erreur dans la tâche : %s"
L["COMMAND_DEBUG_HELP"] = "Activer/Désactiver le mode débogage."
L["COMMAND_STATUS_HELP"] = "Afficher l'état du mode débogage."
L["COMMAND_INIT_HELP"] = "Créer ou mettre à jour les macros de classe."
L["DEBUG_ACTIVATED"] = "Mode débogage |cff00ff00activé|r"
L["DEBUG_DEACTIVATED"] = "Mode débogage |cffff0000désactivé|r"
L["KEY_BINDINGS_SAVED"] = "Raccourcis sauvegardés."
L["KEY_BINDINGS_LOADED"] = "Raccourcis chargés."
L["ACTIONBARS_SAVED"] = "Barres d'action sauvegardées."
L["ACTIONBARS_LOADED"] = "Barres d'action chargées."
L["COMMAND_SAVE_BINDINGS_HELP"] = "Sauvegarder les raccourcis."
L["COMMAND_LOAD_BINDINGS_HELP"] = "Charger les raccourcis."
L["COMMAND_SAVE_BARS_HELP"] = "Sauvegarder les barres d'action."
L["COMMAND_LOAD_BARS_HELP"] = "Charger les barres d'action."
L["COMMAND_EMPTY_BARS_HELP"] = "Vider les barres d'action."
L["INVALID_ACTION_SLOT"] = "Emplacement d'action invalide : %s"
L["SPELL_NOT_FOUND"] = "Sort non trouvé : %s"
L["ITEM_NOT_FOUND"] = "Objet non trouvé : %s"
L["MACRO_NOT_FOUND"] = "Macro non trouvée : %s"
L["INVALID_ACTION_TYPE"] = "Type d'action invalide : %s"
L["ACTION_PLACED_SUCCESS"] = "%s (ID: %s) placé avec succès dans l'emplacement %s"
L["ACTION_PLACED_FAILED"] = "Échec du placement de %s %s (ID: %s) dans l'emplacement %s"
L["ACTION_CLEARED_SUCCESS"] = "Emplacement d'action %s vidé avec succès"
L["ACTION_CLEARED_FAILED"] = "Échec du vidage de l'emplacement d'action %s"
L["ACTIONS_CLEARED_COMPLETE"] = "Vidage des emplacements d'action %s terminé en %.4f secondes"
L["CLEARING_ACTIONS_START"] = "Début : Vidage des emplacements d'action"
L["MOUNT_CANNOT_BE_PLACED"] = "Les montures ne sont pas gérées."
L["COMMAND_HELP_HELP"] = "Lister les commandes disponibles."
L["COMMAND_MACRO_HELP"] = "Gérer les macros."
L["COMMAND_BARS_HELP"] = "Gérer les barres d'action."
L["COMMAND_BINDINGS_HELP"] = "Gérer les raccourcis."