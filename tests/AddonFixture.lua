return function(T, locale)
    local env = T.sandbox()
    local s = {
        frames = {}, output = {}, slots = {}, macros = {}, spells = {}, items = {},
        created = {}, edited = {}, placements = {}, pickups = {}, imports = {},
        configs = {}, exports = {}, configIDs = {}, bindingRows = {}, assignments = {},
        savedBindings = {}, requests = {}, class = "DRUID", spec = 1, specID = 102,
        player = "TestPlayer", fps = 60, combat = false,
    }
    env.RuilhennDB = {}
    env.SlashCmdList = {}
    env.print = function(message) table.insert(s.output, message) end
    env.GetLocale = function() return locale or "enUS" end
    env.debugprofilestop = function() return 10 end
    env.UnitName = function() return s.player end
    env.UnitClass = function() return "LocalizedClass", s.class end
    env.GetSpecialization = function() return s.spec end
    env.GetSpecializationInfo = function() return s.specID end
    env.InCombatLockdown = function() return s.combat end
    env.GetFramerate = function() return s.fps end
    env.CreateFrame = function(_, name)
        local frame = { scripts = {}, events = {} }
        function frame:SetScript(script, callback) self.scripts[script] = callback end
        function frame:RegisterEvent(event) self.events[event] = true end
        table.insert(s.frames, frame)
        if name then env[name] = frame end
        return frame
    end
    function s:tick()
        local count = #self.frames
        for i = 1, count do
            local frame = self.frames[i]
            if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, 1 / self.fps) end
        end
    end
    function s:drain()
        for _ = 1, 100 do
            local pending = false
            for _, frame in ipairs(self.frames) do
                if frame.scripts.OnUpdate then pending = true end
            end
            if not pending then return end
            self:tick()
        end
        error("queue did not become idle within 100 frames")
    end
    env.ClearCursor = function() s.cursor = nil end
    local function pickup(kind, id)
        s.cursor = { kind, id }
        table.insert(s.pickups, { kind, id })
    end
    env.PickupAction = function(slot)
        local action = s.slots[slot]
        s.slots[slot] = s.cursor
        s.cursor = action
        table.insert(s.pickups, { "action", slot })
    end
    env.PlaceAction = function(slot)
        table.insert(s.placements, slot)
        if not s.rejectPlacement then
            s.slots[slot], s.cursor = s.cursor, s.slots[slot]
        end
    end
    env.GetActionInfo = function(slot)
        local action = s.slots[slot]
        if action then return unpack(action, 1, 3) end
    end
    env.GetActionText = function(slot)
        local action = s.slots[slot]
        local macro = action and s.macros[action[2]]
        return macro and macro.name
    end
    env.GetMacroInfo = function(id)
        local macro = s.macros[id]
        if not macro and type(id) == "string" then
            for _, candidate in pairs(s.macros) do
                if candidate.name == id then macro = candidate; break end
            end
        end
        if macro then return macro.name, macro.icon, macro.body end
    end
    env.PickupMacro = function(id) pickup("macro", id) end
    env.PickupItem = function(id) pickup("item", id) end
    env.C_Item = { GetItemInfo = function(id) return s.items[id] end }
    env.C_Spell = {
        GetSpellInfo = function(id)
            if s.spells[id] then return { name = s.spells[id] } end
        end,
        GetSpellName = function(id) return s.spells[id] end,
        PickupSpell = function(id) pickup("spell", id) end,
    }
    env.C_MountJournal = {}
    env.Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 } }
    env.CreateMacro = function(name, icon, body, perCharacter)
        table.insert(s.created, { name, icon, body, perCharacter })
        for i = 121, 150 do
            if not s.macros[i] then
                s.macros[i] = { name = name, icon = icon, body = body }
                return i
            end
        end
        return nil
    end
    env.EditMacro = function(index, name, icon, body)
        table.insert(s.edited, { index, name, icon, body })
        s.macros[index] = { name = name, icon = icon, body = body }
        return index
    end
    env.C_ClassTalents = {
        GetConfigIDsBySpecID = function(specID) return s.configIDs[specID] or {} end,
        HasUnspentTalentPoints = function() return s.unspent end,
        HasUnspentHeroTalentPoints = function() return s.unspentHero end,
        RequestNewConfig = function(name)
            table.insert(s.requests, name)
            return not s.rejectCreation
        end,
        SetUsesSharedActionBars = function() end,
        ImportLoadout = function(configID, entries, name, importString)
            table.insert(s.imports, { configID, entries, name, importString })
            -- Record the call, but never let invalid placeholder data count as success.
            if type(entries[1]) ~= "table" or not entries[1].ranksGranted then
                return false, "Invalid entries"
            end
            return true, ""
        end,
    }
    env.C_Traits = {
        GetConfigInfo = function(id) return s.configs[id] end,
        GenerateImportString = function(id) return s.exports[id] end,
    }
    env.GetCurrentBindingSet = function() return 2 end
    env.GetNumBindings = function() return #s.bindingRows end
    env.GetBinding = function(i) return unpack(s.bindingRows[i], 1, 4) end
    env.SetBinding = function(key, command)
        table.insert(s.assignments, { key, command })
        return true
    end
    env.SaveBindings = function(set) table.insert(s.savedBindings, set) end

    local ns = {}
    local function load(path) return T.load(path, env, ns) end
    load("Core.lua")
    load("l10n/enUS.lua")
    load("l10n/frFR.lua")
    load("Log.lua")
    load("Utils.lua")
    return env, ns, s, load
end
