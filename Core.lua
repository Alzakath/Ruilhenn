-- Core.lua
local addonName, ns = ...

-- WoW API
local debugprofilestop = debugprofilestop

ns.L = {} -- Locale table
ns.Log = {}
ns.Utils = {}
ns.Config = {}
ns.MacroManager = {}
ns.ActionBarsManager = {}
ns.BindingsManager = {}
ns.MacroTemplates  = {}
ns.startTime = debugprofilestop()
ns.Commands = {}
