-- TalentManager.lua
local _, ns = ...
ns.TalentManager = {}
local TalentManager = ns.TalentManager
local Commands = ns.Commands

-- WoW API
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
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
                    importString = exportString
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

function TalentManager:Load()
    ns.Log:Debug("TalentManager:Load() started.")
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
    
    -- Get current configs to avoid duplicates
    local configMap = TalentManager:GetConfigMap(specID)
    
    local importedCount = 0
    local creationRequested = false
    for _, build in ipairs(savedBuilds) do
        
        local configID = configMap[build.name]

        ns.Log:Debug(string.format("Checking build '%s' (configID: %s)", tostring(build.name), tostring(configID)))
        
        if not configID then
            -- Try to create new config
            if C_ClassTalents.RequestNewConfig then
                C_ClassTalents.RequestNewConfig(build.name)
                ns.Log:Message((L["TALENT_CREATION_REQUESTED"] or "Requested creation of loadout '%s'. Please wait a moment and try Load again."):format(build.name))
                creationRequested = true

                configMap = TalentManager:GetConfigMap(specID)
                configID = configMap[build.name]
            else
                ns.Log:Error(L["TALENT_CREATE_FAILED"] or "Cannot create config (API missing).")
            end
        end

        if configID then
            -- Import the string
            local entries = {
                ["nodeID"] = 1,
                ["ranksPurchased"] = 1,
                ["selectionEntryID"] = 1
            }
            local success = C_ClassTalents.ImportLoadout(configID, entries, build.importString, build.name)
            if success then
                importedCount = importedCount + 1
                ns.Log:Message((L["TALENT_IMPORTED"] or "Imported talent build: %s"):format(build.name))
            else
                ns.Log:Error((L["TALENT_IMPORT_FAILED"] or "Failed to import: %s"):format(build.name))
            end
        end
    end
    
    if importedCount > 0 or creationRequested then
        ns.Log:Message(L["TALENTS_LOADED"] or "Talent load process complete.")
    else
        ns.Log:Message(L["NO_NEW_TALENTS"] or "No new talent builds to import.")
    end
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