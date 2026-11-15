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

local function editorOpen()
    local editor = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    return editor and editor:IsVisible()
end

function TalentManager:RestoreBlockReason()
    if editorOpen() then return L.TALENT_EDITOR_OPEN end
    if self.restore then return L.TALENT_RESTORE_BUSY end
    local activeID = C_ClassTalents.GetActiveConfigID()
    if activeID and C_Traits.ConfigHasStagedChanges and C_Traits.ConfigHasStagedChanges(activeID) then
        return L.TALENT_PENDING_CHANGES
    end
end

function TalentManager:Status()
    local activeID = C_ClassTalents.GetActiveConfigID()
    ns.Log:Message(L.TALENT_CLIENT_STATUS:format(tostring(activeID),
        tostring(activeID and C_Traits.ConfigHasStagedChanges(activeID) or false),
        tostring(not not editorOpen()), tostring(C_ClassTalents.CanCreateNewConfig())))
    local savedID = self.lastCreatedConfigID
    if savedID then
        ns.Log:Message(L.TALENT_SAVED_CONFIG_STATUS:format(tostring(savedID),
            tostring(C_Traits.ConfigHasStagedChanges(savedID)), tostring(C_ClassTalents.IsConfigPopulated(savedID))))
    end
    if self.cleanupReason then ns.Log:Message(L.TALENT_CLEANUP_REASON:format(self.cleanupReason)) end
end

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
    if ns.TemplateStore then ns.TemplateStore:Record("talents") end
    ns.Log:Message(L["TALENTS_SAVED"] or "Talent builds saved.")
end

function TalentManager:GetConfigMap(specID)
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
    if ns.TemplateBrowser then ns.TemplateBrowser:UpdateActionState() end
end

-- ImportLoadout itself requests a new saved loadout. Its configID is the
-- active configuration used for decoding, not an empty pre-created target.
function TalentManager:ImportSavedBuild(build, configID, specID)
    local entries, reason = ns.TalentImport:Decode(build.importString, configID, specID)
    if entries then
        local ok, success, importError = pcall(C_ClassTalents.ImportLoadout,
            configID, entries, build.name, build.importString)
        if ok and success then return true end
        reason = ok and importError or success
    end
    if not reason or reason == "" then reason = L.TALENT_IMPORT_REJECTED end
    ns.Log:Error(L.TALENT_IMPORT_ERROR:format(build.name, tostring(reason)))
    ns.Log:Debug(L.TALENT_REJECTION_STATE:format(tostring(configID),
        tostring(configID and C_Traits.ConfigHasStagedChanges(configID) or false),
        tostring(C_ClassTalents.CanCreateNewConfig()), tostring(not not editorOpen())))
    return false
end

function TalentManager:CleanupImportScratch(state, savedID)
    local context = state.importContext
    if not context then return true end
    local current = C_ClassTalents.GetActiveConfigID()
    if current ~= context.id then
        self.cleanupReason = "active-config-changed"
        self:StopRestore()
        ns.Log:Warning(L.TALENT_SCRATCH_UNIDENTIFIED)
        self:Status()
        return false
    end
    if not C_Traits.ConfigHasStagedChanges(context.id) then return true end
    local savedExport = C_Traits.GenerateImportString(savedID)
    local stagedExport = C_Traits.GenerateImportString(context.id)
    -- Never roll back an existing draft or an unrelated/interleaved edit.
    if context.id ~= current or context.id == savedID or editorOpen() or InCombatLockdown() or
        GetSpecialization() ~= state.specIndex or type(savedExport) ~= "string" or savedExport == "" or
        type(context.scratch) ~= "string" or stagedExport ~= context.scratch or
        C_Traits.ConfigHasStagedChanges(savedID) then
        self.cleanupReason = not context.scratch and "no-synchronous-import-snapshot" or
            stagedExport ~= context.scratch and "active-export-changed-since-import" or
            not savedExport and "saved-export-unavailable" or "context-or-saved-state-changed"
        self:StopRestore()
        ns.Log:Warning(L.TALENT_SCRATCH_UNIDENTIFIED)
        self:Status()
        return false
    end
    state.cleaning = true
    local ok, success = pcall(C_Traits.RollbackConfig, context.id)
    state.cleaning = nil
    local verified = ok and success and C_ClassTalents.GetActiveConfigID() == context.id and
        not C_Traits.ConfigHasStagedChanges(context.id) and
        C_Traits.GenerateImportString(context.id) == context.baseline and
        C_Traits.GenerateImportString(savedID) == savedExport
    if not verified then
        self.cleanupReason = "rollback-verification-failed"
        self:StopRestore()
        ns.Log:Error(L.TALENT_SCRATCH_FAILED)
        self:Status()
        return false
    end
    ns.Log:Debug(L.TALENT_SCRATCH_CLEANED)
    return self.restore == state
end

function TalentManager:ScheduleNext(state, delay)
    if self.restore ~= state then return end
    state.advancePending = true
    state.timer = C_Timer.NewTimer(delay or 0, function()
        if self.restore ~= state then return end
        state.timer, state.advancePending = nil, nil
        self:ContinueRestore(state)
    end)
end

function TalentManager:ContinueRestore(state)
    if self.restore ~= state or state.waiting or state.advancePending then return end
    if InCombatLockdown() or GetSpecialization() ~= state.specIndex then
        self:StopRestore()
        ns.Log:Error(L.TALENT_RESTORE_CANCELLED)
        return
    end
    if editorOpen() then self:StopRestore(); ns.Log:Warning(L.TALENT_EDITOR_OPEN); return end
    while state.index <= #state.builds do
        local build = state.builds[state.index]
        local map = self:GetConfigMap(state.specID)
        local activeID = C_ClassTalents.GetActiveConfigID()
        local entries, reason = ns.TalentImport:Decode(build.importString, activeID, state.specID)
        if not entries or type(build.name) ~= "string" or build.name == "" then
            state.index = state.index + 1
            state.failed = state.failed + 1
            ns.Log:Error(L.TALENT_IMPORT_ERROR:format(tostring(build.name or ""), reason or L.TALENT_STRING_INVALID))
        elseif map[build.name] then
            state.index = state.index + 1
            state.kept = state.kept + 1
            ns.Log:Message(L.TALENT_EXISTING_KEPT:format(build.name))
        else
            local staged = activeID and C_Traits.ConfigHasStagedChanges(activeID)
            if staged or not C_ClassTalents.CanCreateNewConfig() then
                state.readyChecks = (state.readyChecks or 0) + 1
                if state.readyChecks >= 40 then
                    self:StopRestore()
                    if staged then
                        ns.Log:Warning(L.TALENT_IMPORT_SETTLE_TIMEOUT:format(build.name))
                        self:Status()
                    else ns.Log:Error(L.TALENT_CREATE_NOT_READY:format(build.name)) end
                    return
                end
                if state.readyChecks == 1 then ns.Log:Message(staged and L.TALENT_WAIT_SETTLE or L.TALENT_WAIT_READY) end
                state.timer = C_Timer.NewTimer(0.25, function()
                    if self.restore == state then state.timer = nil; self:ContinueRestore(state) end
                end)
                return
            end
            state.readyChecks = nil
            local baseline = C_Traits.GenerateImportString(activeID)
            if type(baseline) ~= "string" or baseline == "" then
                self:StopRestore()
                ns.Log:Error(L.TALENT_BASELINE_UNAVAILABLE)
                return
            end
            state.importContext = { id = activeID, baseline = baseline }
            self.cleanupReason = nil
            state.waiting, state.before = build, {}
            state.createdID = nil
            state.requiresPopulated = #entries > 0
            for _, id in pairs(map) do state.before[id] = true end
            if activeID then state.before[activeID] = true end
            state.currentIndex = state.index
            state.index = state.index + 1
            state.capturing = true
            local accepted = self:ImportSavedBuild(build, activeID, state.specID)
            state.capturing = nil
            if accepted then
                state.retries = 0
                if self.restore ~= state then return end
                -- Read immediately on return, before another frame/user action can
                -- intervene. The saved and active configs need not serialize alike.
                if C_ClassTalents.GetActiveConfigID() == activeID and C_Traits.ConfigHasStagedChanges(activeID) then
                    local scratch = C_Traits.GenerateImportString(activeID)
                    if type(scratch) == "string" and scratch ~= "" then state.importContext.scratch = scratch end
                end
                if state.createdID then
                    self:OnRestoreEvent("TRAIT_CONFIG_UPDATED", state.createdID)
                end
                if self.restore == state and state.waiting == build then
                    ns.Log:Message(L.TALENT_CREATE_WAIT:format(build.name))
                    state.timer = C_Timer.NewTimer(15, function()
                        if self.restore == state and state.waiting == build then
                            self:StopRestore()
                            ns.Log:Error(L.TALENT_CREATE_TIMEOUT:format(build.name))
                        end
                    end)
                end
                return
            end
            state.waiting = nil
            -- ImportLoadout synchronously rejected the request, so no native
            -- creation is pending. Retry this same build a small bounded number
            -- of times; accepted requests are never retried.
            state.retries = (state.retries or 0) + 1
            if state.retries <= 2 then
                state.index = state.currentIndex
                ns.Log:Warning(L.TALENT_IMPORT_RETRY:format(build.name, state.retries, 2))
                self:ScheduleNext(state, state.retries)
                return
            end
            state.failed = state.failed + 1
            state.retries = 0
            if state.index <= #state.builds then self:ScheduleNext(state); return end
        end
    end
    self:StopRestore()
    local message = L.TALENT_RESTORE_COMPLETE:format(state.imported, state.failed)
    if state.kept > 0 then message = message .. " " .. L.TALENT_KEPT_COUNT:format(state.kept) end
    ns.Log:Message(message)
end

function TalentManager:OnRestoreEvent(event, info)
    local state = self.restore
    if not state then return end
    if InCombatLockdown() or GetSpecialization() ~= state.specIndex then
        self:StopRestore()
        ns.Log:Error(L.TALENT_RESTORE_CANCELLED)
        return
    end
    -- A staged flag appearing after our accepted import is not evidence of a
    -- user draft. Confirm its saved result first, then gate further requests.
    if editorOpen() then self:StopRestore(); ns.Log:Warning(L.TALENT_EDITOR_OPEN); return end
    local build = state.waiting
    if state.cleaning then return end
    if not build then return end
    if event == "TRAIT_CONFIG_CREATED" then
        if type(info) ~= "table" or info.type ~= Enum.TraitConfigType.Combat or
            info.name ~= build.name or not info.ID or state.before[info.ID] then return end
        state.createdID = info.ID
    elseif event ~= "TRAIT_CONFIG_UPDATED" or info ~= state.createdID then return end
    if state.capturing then return end
    local id = state.createdID
    local actual = id and C_Traits.GetConfigInfo(id)
    if not actual or actual.name ~= build.name then return end
    if state.requiresPopulated and not C_ClassTalents.IsConfigPopulated(id) then return end
    self.lastCreatedConfigID = id
    if state.timer then state.timer:Cancel(); state.timer = nil end
    state.waiting, state.createdID = nil, nil
    local settingsOK, settingsError = true, nil
    if build.usesSharedActionBars ~= nil then
        settingsOK, settingsError = pcall(C_ClassTalents.SetUsesSharedActionBars, id, build.usesSharedActionBars)
    end
    if not self:CleanupImportScratch(state, id) then return end
    state.importContext = nil
    if settingsOK then
        state.imported = state.imported + 1
        ns.Log:Message(L.TALENT_IMPORTED:format(build.name))
    else
        state.failed = state.failed + 1
        ns.Log:Error(L.TALENT_SHARED_BARS_FAILED:format(build.name, tostring(settingsError)))
    end
    -- Leave native creation/update/rollback callbacks before sending a new
    -- request. A populated saved config does not imply event dispatch ended.
    if state.index <= #state.builds then self:ScheduleNext(state)
    else self:ContinueRestore(state) end
end
function TalentManager:Load(talentIndex)
    if InCombatLockdown() then
        ns.Log:Error(L["TALENT_IMPORT_COMBAT"] or "Cannot import talent builds in combat.")
        return
    end
    if self.restore then
        ns.Log:Error(L["TALENT_RESTORE_BUSY"] or "A talent restore is already running. Wait for it to finish.")
        return
    end
    local blocked = self:RestoreBlockReason()
    if blocked then ns.Log:Warning(blocked); return false end

    -- Check for unspent talent points
    if C_ClassTalents.HasUnspentTalentPoints() or C_ClassTalents.HasUnspentHeroTalentPoints() then
        ns.Log:Message(L["UNSPENT_TALENT_POINTS"] or "Load aborted: You have unspent talent points.")
        return
    end

    local specIndex = GetSpecialization()
    if not specIndex then return end
    
    local specID = GetSpecializationInfo(specIndex)
    local _, playerClass = UnitClass("player")
    
    if not RuilhennDB.talents or not RuilhennDB.talents[playerClass] or not RuilhennDB.talents[playerClass][specIndex] then
        ns.Log:Message(L["NO_TALENTS_SAVED"] or "No saved talents found for this specialization.")
        return
    end
    
    local savedBuilds = RuilhennDB.talents[playerClass][specIndex]
    if talentIndex ~= nil then
        if type(talentIndex) ~= "number" or not savedBuilds[talentIndex] then return false end
        savedBuilds = { savedBuilds[talentIndex] }
    end
    if type(C_ClassTalents.CanCreateNewConfig) ~= "function" or type(C_ClassTalents.IsConfigPopulated) ~= "function" or
        type(C_Traits.ConfigHasStagedChanges) ~= "function" or type(C_Traits.RollbackConfig) ~= "function" then
        ns.Log:Error(L.TALENT_RESTORE_API_UNAVAILABLE)
        return false
    end
    local state = { builds = {}, index = 1, imported = 0, failed = 0, kept = 0, specIndex = specIndex, specID = specID }
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
    if ns.TemplateBrowser then ns.TemplateBrowser:UpdateActionState() end
    self.restoreFrame:RegisterEvent("TRAIT_CONFIG_CREATED")
    self.restoreFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self.restoreFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.restoreFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:ContinueRestore(state)
end

TalentManager.subcommands = {
    ["save"] = function() TalentManager:Save() end,
    ["load"] = function() TalentManager:Load() end,
    ["status"] = function() TalentManager:Status() end,
}

Commands["talents"] = function(subcommand)
    local func = TalentManager.subcommands[subcommand]
    if type(func) == "function" then
        local success, err = pcall(func)
        if not success then
            ns.Log:Debug("Command execution error: " .. tostring(err))
        end
    else
        ns.Log:Message(L.TALENTS_USAGE)
    end
end
