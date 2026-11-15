return function(T, locale)
    local env = T.sandbox()
    local s = {
        frames = {}, output = {}, slots = {}, macros = {}, spells = {}, items = {},
        created = {}, edited = {}, placements = {}, pickups = {}, imports = {},
        configs = {}, exports = {}, configIDs = {}, bindingRows = {}, bindingSets = { [1] = {}, [2] = {} },
        commandContexts = {},
        currentSet = 2, assignments = {},
        savedBindings = {}, requests = {}, class = "DRUID", spec = 1, specID = 102,
        player = "TestPlayer", fps = 60, combat = false, timers = {},
        clickProfile = {}, clickWrites = {}, unbindable = {}, missingClickSpells = {},
    }
    env.RuilhennDB = {}
    env.Enum = {
        ClickBindingType = { None = 0, Spell = 1, Macro = 2, Interaction = 3, PetAction = 4 },
        ClickBindingInteraction = { Target = 1, OpenContextMenu = 2 },
        SpellBookSpellBank = { Player = 0 },
    }
    env.C_SpellBook = { IsSpellInSpellBook = function(id, bank, overrides)
        assert(bank == env.Enum.SpellBookSpellBank.Player and type(overrides) == "boolean")
        return not s.missingClickSpells[id]
    end }
    env.C_ClickBindings = {
        GetProfileInfo = function()
            if s.getClickError then error("Read rejected") end
            return s.clickProfile
        end,
        CanSpellBeClickBound = function(id) return not s.unbindable[id] end,
        SetProfileByInfo = function(profile)
            if s.throwClicks then error("Write restricted") end
            table.insert(s.clickWrites, profile)
            if s.rejectClicks then return end
            s.clickProfile = {}
            for _, row in ipairs(profile) do
                local copy = {}
                for key, value in pairs(row) do copy[key] = value end
                table.insert(s.clickProfile, s.reorderClicks and 1 or (#s.clickProfile + 1), copy)
            end
            -- The real API declares no return; readback must determine success.
        end,
    }
    env.SlashCmdList = {}
    env.print = function(message) table.insert(s.output, message) end
    env.GetLocale = function() return locale or "enUS" end
    env.GetBuildInfo = function() return "12.1.5", "70783", "Nov 4 2026", 120105 end
    env.debugprofilestop = function() return 10 end
    env.UnitName = function() return s.player end
    env.UnitFullName = function() return s.player, "TestRealm" end
    env.GetRealmName = function() return "TestRealm" end
    env.time = function() return 1794528000 end
    env.date = os.date
    env.UnitClass = function() return "LocalizedClass", s.class end
    env.C_ClassColor = { GetClassColor = function(class)
        local colors = {
            DRUID = { r = 1, g = 0.49, b = 0.04 },
            PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
            PRIEST = { r = 1, g = 1, b = 1 },
            DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
        }
        return colors[class]
    end }
    -- Deprecated global wrappers are deliberately absent in every fixture.
    env.C_SpecializationInfo = {
        GetSpecialization = function() return s.spec end,
        GetSpecializationInfo = function(specIndex)
            assert(specIndex == s.spec, "specialization index expected")
            return s.specID, "LocalizedSpec", "Description", 123, "DAMAGER"
        end,
    }
    env.InCombatLockdown = function() return s.combat end
    env.GetFramerate = function() return s.fps end
    env.CreateFrame = function(_, name)
        local frame = { scripts = {}, events = {} }
        function frame:SetScript(script, callback) self.scripts[script] = callback end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        table.insert(s.frames, frame)
        if name then env[name] = frame end
        return frame
    end
    env.C_Timer = { NewTimer = function(_, callback)
        local timer = { callback = callback }
        function timer:Cancel() self.cancelled = true end
        table.insert(s.timers, timer)
        return timer
    end }
    function s:fire(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function s:expireTimers()
        local timers = self.timers
        self.timers = {}
        for _, timer in ipairs(timers) do if not timer.cancelled then timer.callback() end end
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
    env.C_ActionBar = {
        GetActionText = function(slot)
            local action = s.slots[slot]
            local macro = action and s.macros[action[2]]
            return macro and macro.name
        end,
    }
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
    s.itemRequests = {}
    env.C_Item = {
        GetItemInfo = function(id) return s.items[id] end,
        PickupItem = function(id) pickup("item", id) end,
        RequestLoadItemDataByID = function(id) table.insert(s.itemRequests, id) end,
    }
    function s:resolveItem(id, name, success)
        self.items[id] = name
        self:fire("ITEM_DATA_LOAD_RESULT", id, success ~= false)
    end
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
        GetActiveConfigID = function() return 10 end,
        CanCreateNewConfig = function() return not s.notReady end,
        IsConfigPopulated = function(id) return s.configs[id] and s.configs[id].populated ~= false end,
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
        ConfigHasStagedChanges = function(id)
            if s.stagedConfigs and s.stagedConfigs[id] ~= nil then return s.stagedConfigs[id] end
            return id == env.C_ClassTalents.GetActiveConfigID() and not not s.stagedTalents
        end,
        RollbackConfig = function(id)
            s.rollbacks = s.rollbacks or {}
            table.insert(s.rollbacks, id)
            if s.rejectRollback then return false end
            s.stagedTalents = false
            return true
        end,
        GetConfigInfo = function(id) return s.configs[id] end,
        GenerateImportString = function(id) return s.exports[id] end,
    }
    env.GetCurrentBindingSet = function() return s.currentSet end
    env.GetNumBindings = function()
        if s.getNumBindingsFailure then error("GetNumBindings rejected") end
        return #s.bindingRows
    end
    env.GetBinding = function(i)
        if s.bindingReadFailure and (not s.bindingReadFailureSet or s.loadedSet == s.bindingReadFailureSet) then
            error("GetBinding rejected")
        end
        return unpack(s.bindingRows[i])
    end
    env.C_KeyBindings = {
        GetBindingContextForAction = function(action)
            if s.bindingContextReadFailure then error("GetBindingContextForAction rejected") end
            return s.commandContexts[action]
        end,
    }
    local function copyRows(rows)
        local copy = {}
        for _, row in ipairs(rows or {}) do
            local nextRow = {}
            for key, value in pairs(row) do nextRow[key] = value end
            copy[#copy + 1] = nextRow
        end
        return copy
    end
    env.LoadBindings = function(set)
        if s.loadBindingFailure or s.loadBindingFailureSet == set then error("LoadBindings rejected") end
        s.loadedSet = set
        s.bindingRows = copyRows(s.bindingSets[set])
    end
    env.SetBinding = function(key, command, context)
        table.insert(s.assignments, { key, command, context })
        if s.rejectBindingKey == key then return false end
        local map = {}
        for _, row in ipairs(s.bindingRows) do
            local rowContext = s.commandContexts[row[1]]
            for index = 3, #row do
                local bindingKey = row[index]
                local identity = tostring(rowContext == nil and "<nil>" or rowContext) .. "\001" .. tostring(bindingKey)
                local target = tostring(context == nil and "<nil>" or context) .. "\001" .. tostring(key)
                if bindingKey and identity ~= target then
                    map[identity] = { key = bindingKey, command = row[1], context = rowContext }
                end
            end
        end
        if command then
            local identity = tostring(context == nil and "<nil>" or context) .. "\001" .. tostring(key)
            map[identity] = { key = key, command = command, context = context }
        end
        local grouped = {}
        for _, assignment in pairs(map) do
            local identity = assignment.command .. "\001" .. tostring(assignment.context == nil and "<nil>" or assignment.context)
            grouped[identity] = grouped[identity] or { command = assignment.command, keys = {} }
            table.insert(grouped[identity].keys, assignment.key)
        end
        local rows = {}
        for _, group in pairs(grouped) do
            table.sort(group.keys)
            local row = { group.command, "FIXTURE" }
            for _, bindKey in ipairs(group.keys) do row[#row + 1] = bindKey end
            rows[#rows + 1] = row
        end
        table.sort(rows, function(a, b)
            if a[1] ~= b[1] then return a[1] < b[1] end
            local aContext, bContext = s.commandContexts[a[1]], s.commandContexts[b[1]]
            return tostring(aContext) < tostring(bContext)
        end)
        s.bindingRows = rows
        return true
    end
    env.SaveBindings = function(set)
        if s.saveBindingFailure then error("SaveBindings rejected") end
        table.insert(s.savedBindings, set)
        s.bindingSets[set] = copyRows(s.bindingRows)
        s.currentSet = set
    end

    local ns = {}
    local function load(path) return T.load(path, env, ns) end
    load("Core.lua")
    load("l10n/enUS.lua")
    load("l10n/frFR.lua")
    load("Log.lua")
    load("Utils.lua")
    load("ItemData.lua")
    return env, ns, s, load
end
