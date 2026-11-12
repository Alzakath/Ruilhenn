-- TalentManager.lua
local _, ns = ...
ns.TalentManager = {}
local TalentManager = ns.TalentManager
local Commands = ns.Commands

-- WoW API
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local UnitClass = UnitClass
local C_ClassTalents = C_ClassTalents
local C_Traits = C_Traits

-- Fallback for localization
local L = ns.L or {}

function TalentManager:Save()
    local specIndex = GetSpecialization()
    if not specIndex then return end
    
    local specID = GetSpecializationInfo(specIndex)
    local _, playerClass = UnitClass("player")
    
    -- Initialize DB
    RuilhennDB.talents = RuilhennDB.talents or {}
    RuilhennDB.talents[playerClass] = RuilhennDB.talents[playerClass] or {}
    
    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
    local savedBuilds = {}
    
    for _, configID in ipairs(configIDs) do
        local info = C_Traits.GetConfigInfo(configID)
        if info and info.name then
            -- Generate export string
            local exportString = C_Traits.GenerateImportString(configID)
            if exportString then
                table.insert(savedBuilds, {
                    name = info.name,
                    importString = exportString,
                    usesSharedActionBars = info.usesSharedActionBars
                })
            end
        end
    end
    
    RuilhennDB.talents[playerClass][specIndex] = savedBuilds
    ns.Log:Message(L["TALENTS_SAVED"] or "Talent builds saved.")
end

function TalentManager:GetConfigMap(specID)
    ns.Log:Debug("TalentManager:GetConfigMap() started.")
    local configMap = {}
    
    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    for _, id in ipairs(configIDs) do
        local info = C_Traits.GetConfigInfo(id)
        if info then
            configMap[info.name] = id
        end
    end
    
    return configMap
end

function TalentManager:StopRestore()
    local state = self.restore
    self.restore = nil
    if state and state.timer then state.timer:Cancel() end
    if self.restoreFrame then self.restoreFrame:UnregisterAllEvents() end
end

function TalentManager:ImportSavedBuild(build, configID, specID)
    local entries, reason = ns.TalentImport:Decode(build.importString, configID, specID)
    if entries then
        local ok, success, importError = pcall(C_ClassTalents.ImportLoadout,
            configID, entries, build.name, build.importString)
        if ok and success then
            if build.usesSharedActionBars ~= nil then
                C_ClassTalents.SetUsesSharedActionBars(configID, build.usesSharedActionBars)
            end
            ns.Log:Message((L["TALENT_IMPORTED"] or "Imported talent build: %s"):format(build.name))
            return true
        end
        reason = ok and importError or success
    end
    if not reason or reason == "" then
        reason = L["TALENT_IMPORT_REJECTED"] or "The game rejected the talent import."
    end
    ns.Log:Error((L["TALENT_IMPORT_ERROR"] or "Could not import talent build %s: %s"):format(build.name, tostring(reason)))
    return false
end

function TalentManager:ContinueRestore(state)
    if self.restore ~= state then return end
    if InCombatLockdown() or GetSpecialization() ~= state.specIndex then
        self:StopRestore()
        ns.Log:Error(L["TALENT_RESTORE_CANCELLED"] or "Talent restore stopped because combat or specialization changed. Run /ruil talents load again when ready.")
        return
    end
    while state.index <= #state.builds do
        if self.restore ~= state then return end
        local build = state.builds[state.index]
        state.index = state.index + 1
        local map = self:GetConfigMap(state.specID)
        local configID = map[build.name]
        local entries, reason = ns.TalentImport:Decode(build.importString,
            configID or C_ClassTalents.GetActiveConfigID(), state.specID)
        if not entries or type(build.name) ~= "string" or build.name == "" then
            state.failed = state.failed + 1
            ns.Log:Error((L["TALENT_IMPORT_ERROR"] or "Could not import talent build %s: %s"):format(
                tostring(build.name or ""), reason or L["TALENT_STRING_INVALID"] or "Invalid talent build."))
        elseif configID then
            if self:ImportSavedBuild(build, configID, state.specID) then
                state.imported = state.imported + 1
            else
                state.failed = state.failed + 1
            end
        else
            -- Install the waiter before the request; never infer synchronous creation.
            state.waiting = build
            state.before = {}
            for _, id in pairs(map) do state.before[id] = true end
            local activeID = C_ClassTalents.GetActiveConfigID()
            if activeID then state.before[activeID] = true end
            local ok, accepted = pcall(C_ClassTalents.RequestNewConfig, build.name)
            if ok and accepted then
                ns.Log:Message((L["TALENT_CREATE_WAIT"] or "Waiting for creation of talent loadout %s."):format(build.name))
                if self.restore == state and state.waiting == build then
                    state.timer = C_Timer.NewTimer(15, function()
                        if self.restore == state and state.waiting == build then
                            self:StopRestore()
                            ns.Log:Error((L["TALENT_CREATE_TIMEOUT"] or "Timed out waiting for talent loadout %s. Check your loadouts before retrying."):format(build.name))
                        end
                    end)
                end
                return
            end
            state.waiting = nil
            state.failed = state.failed + 1
            ns.Log:Error((L["TALENT_CREATE_REJECTED"] or "The game refused to create talent loadout %s."):format(build.name))
        end
    end
    self:StopRestore()
    ns.Log:Message((L["TALENT_RESTORE_COMPLETE"] or "Talent restore finished: %d imported, %d failed."):format(state.imported, state.failed))
end

function TalentManager:OnRestoreEvent(event, info)
    local state = self.restore
    if not state then return end
    if InCombatLockdown() or GetSpecialization() ~= state.specIndex then
        self:ContinueRestore(state)
        return
    end
    if event ~= "TRAIT_CONFIG_CREATED" or not state.waiting or type(info) ~= "table" then return end
    local build = state.waiting
    if info.type ~= Enum.TraitConfigType.Combat or info.name ~= build.name or
        not info.ID or state.before[info.ID] then return end
    local actual = C_Traits.GetConfigInfo(info.ID)
    if not actual or actual.name ~= build.name then return end
    if state.timer then state.timer:Cancel(); state.timer = nil end
    state.waiting = nil
    if self:ImportSavedBuild(build, info.ID, state.specID) then
        state.imported = state.imported + 1
    else
        state.failed = state.failed + 1
    end
    self:ContinueRestore(state)
end

function TalentManager:Load()
    ns.Log:Debug("TalentManager:Load() started.")

    if InCombatLockdown() then
        ns.Log:Error(L["TALENT_IMPORT_COMBAT"] or "Cannot import talent builds in combat.")
        return
    end
    if self.restore then
        ns.Log:Error(L["TALENT_RESTORE_BUSY"] or "A talent restore is already running. Wait for it to finish.")
        return
    end

    -- Check for unspent talent points
    if C_ClassTalents.HasUnspentTalentPoints() or C_ClassTalents.HasUnspentHeroTalentPoints() then
        ns.Log:Message(L["UNSPENT_TALENT_POINTS"] or "Load aborted: You have unspent talent points.")
        return
    end

    local specIndex = GetSpecialization()
    if not specIndex then
        ns.Log:Debug("TalentManager:Load() aborted: No active specialization.")
        return
    end
    
    local specID = GetSpecializationInfo(specIndex)
    local _, playerClass = UnitClass("player")
    
    ns.Log:Debug(string.format("Class=%s, SpecIndex=%s, SpecID=%s", tostring(playerClass), tostring(specIndex), tostring(specID)))

    if not RuilhennDB.talents then
        ns.Log:Debug("RuilhennDB.talents is nil")
    elseif not RuilhennDB.talents[playerClass] then
        ns.Log:Debug("RuilhennDB.talents["..tostring(playerClass).."] is nil")
    end

    if not RuilhennDB.talents or not RuilhennDB.talents[playerClass] or not RuilhennDB.talents[playerClass][specIndex] then
        ns.Log:Message(L["NO_TALENTS_SAVED"] or "No saved talents found for this specialization.")
        return
    end
    
    local savedBuilds = RuilhennDB.talents[playerClass][specIndex]
    ns.Log:Debug(string.format("Found %d saved builds.", #savedBuilds))
    
    local state = { builds = {}, index = 1, imported = 0, failed = 0, specIndex = specIndex, specID = specID }
    for _, build in ipairs(savedBuilds) do
        state.builds[#state.builds + 1] = {
            name = build.name, importString = build.importString, usesSharedActionBars = build.usesSharedActionBars,
        }
    end
    if not self.restoreFrame then
        self.restoreFrame = CreateFrame("Frame")
        self.restoreFrame:SetScript("OnEvent", function(_, event, info) self:OnRestoreEvent(event, info) end)
    end
    self.restore = state
    self.restoreFrame:RegisterEvent("TRAIT_CONFIG_CREATED")
    self.restoreFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.restoreFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:ContinueRestore(state)
end

TalentManager.subcommands = {
    ["save"] = function() TalentManager:Save() end,
    ["load"] = function() TalentManager:Load() end,
}

Commands["talents"] = function(subcommand)
    local func = TalentManager.subcommands[subcommand]
    if type(func) == "function" then
        local success, err = pcall(func)
        if not success then
            ns.Log:Debug("Command execution error: " .. tostring(err))
        end
    else
        ns.Log:Message("Usage: /ruil talents [save|load]")
    end
end
