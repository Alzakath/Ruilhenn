local addonName, ns = ...

-- WoW API
local GetLocale = GetLocale

if GetLocale() ~= "enUS" then return end

ns.L = {}
local L = ns.L

L["LOADED"] = "Version %s loaded"
L["LOADED_TIMER"] = "Ruilhenn took %.4f milliseconds to load"
L["STARTED"] = "/ruil help to get started"
L["CLASS_DETECTED"] = "Player's class detected: %s"
L["MACRO_CREATED"] = "Macro %s created (character-specific)."
L["MACRO_UPDATED"] = "Macro %s updated."
L["NO_MACROS_DEFINED"] = "No macros defined for class %s."
L["ERROR_COROUTINE"] = "Error in coroutine: %s"
L["SETTINGS_FOUND"] = "Loaded settings for %s"
L["SETTINGS_NOT_FOUND"] = "No settings found for %s"
L["TASKS_PROCESSED"] = "All tasks processed."
L["TASKS_ERROR"] = "Error in task: %s"
L["COMMAND_DEBUG_HELP"] = "Toggle debug mode."
L["COMMAND_STATUS_HELP"] = "Show debug mode status."
L["COMMAND_INIT_HELP"] = "Create or Update class specific macros."
L["DEBUG_ACTIVATED"] = "Debug mode |cff00ff00activated|r"
L["DEBUG_DEACTIVATED"] = "Debug mode |cffff0000deactivated|r"
L["KEY_BINDINGS_SAVED"] = "Keybindings saved."
L["KEY_BINDINGS_LOADED"] = "Keybindings loaded."
L["ACTIONBARS_SAVED"] = "Actionbars saved."
L["ACTIONBARS_LOADED"] = "Actionbars loaded."
L["COMMAND_SAVE_BINDINGS_HELP"] = "Save key bindings."
L["COMMAND_LOAD_BINDINGS_HELP"] = "Load key bindings."
L["COMMAND_SAVE_BARS_HELP"] = "Save key action bars."
L["COMMAND_LOAD_BARS_HELP"] = "Load key action bars."
L["COMMAND_EMPTY_BARS_HELP"] = "Empty action bars."
L["INVALID_ACTION_SLOT"] = "Invalid action slot: %s"
L["SPELL_NOT_FOUND"] = "Spell not found: %s"
L["ITEM_NOT_FOUND"] = "Item not found: %s"
L["MACRO_NOT_FOUND"] = "Macro not found: %s"
L["INVALID_ACTION_TYPE"] = "Invalid action type: %s"
L["ACTION_PLACED_SUCCESS"] = "%s (ID: %s) successfully placed in slot %s"
L["ACTION_PLACED_FAILED"] = "Failed to place %s %s (ID: %s) in slot %s"
L["ACTION_CLEARED_SUCCESS"] = "Successfully cleared action slot %s"
L["ACTION_CLEARED_FAILED"] = "Failed to clear action slot %s"
