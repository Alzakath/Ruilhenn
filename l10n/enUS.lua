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
