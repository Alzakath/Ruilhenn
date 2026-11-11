local _, ns = ...
local L = ns.L or {}
ns.TalentImport = {}

-- Retail serialization contract: 8-bit version, 16-bit spec, 16 hash bytes,
-- then node flags in GetTreeNodes order. See tests/README.md for pinned evidence.
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function Reader(text)
    if type(text) ~= "string" or text == "" or text:find("[^A-Za-z0-9+/]") then
        error("TALENT_STRING_INVALID", 0)
    end
    local position = 0
    local function read(width)
        if position + width > #text * 6 then error("TALENT_STRING_INVALID", 0) end
        local result = 0
        for bit = 0, width - 1 do
            local index = math.floor(position / 6) + 1
            local value = alphabet:find(text:sub(index, index), 1, true) - 1
            result = result + (math.floor(value / 2 ^ (position % 6)) % 2) * 2 ^ bit
            position = position + 1
        end
        return result
    end
    local function finish()
        local remaining = #text * 6 - position
        if remaining > 5 or (remaining > 0 and read(remaining) ~= 0) then
            error("TALENT_STRING_INVALID", 0)
        end
    end
    return read, finish
end

local function decode(text, configID, specID)
    local read, finish = Reader(text)
    local version, encodedSpec = read(8), read(16)
    if version ~= C_Traits.GetLoadoutSerializationVersion() then
        error("TALENT_STRING_VERSION", 0)
    end
    if encodedSpec ~= specID then error("TALENT_STRING_SPEC", 0) end
    local hash, emptyHash = {}, true
    for i = 1, 16 do
        hash[i] = read(8)
        if hash[i] ~= 0 then emptyHash = false end
    end
    local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
    local config = configID and C_Traits.GetConfigInfo(configID)
    local matchesTree = false
    for _, id in ipairs(config and config.treeIDs or {}) do
        if id == treeID then matchesTree = true end
    end
    if not treeID or not matchesTree then error("TALENT_TREE_UNAVAILABLE", 0) end
    if not emptyHash then
        local currentHash = C_Traits.GetTreeHash(treeID)
        for i = 1, 16 do
            if not currentHash or hash[i] ~= currentHash[i] then
                error("TALENT_STRING_TREE", 0)
            end
        end
    end
    local nodes = C_Traits.GetTreeNodes(treeID)
    if not nodes or #nodes == 0 then error("TALENT_TREE_UNAVAILABLE", 0) end
    local entries = {}
    for _, nodeID in ipairs(nodes) do
        if read(1) == 1 then
            local purchased = read(1) == 1
            local partial, ranks, choice, choiceIndex = false, 0, false, 1
            if purchased then
                partial = read(1) == 1
                if partial then ranks = read(6) end
                choice = read(1) == 1
                if choice then choiceIndex = read(2) + 1 end
            end
            local node = C_Traits.GetNodeInfo(configID, nodeID)
            if not node or not node.entryIDs or #node.entryIDs == 0 then
                error("TALENT_STRING_INVALID", 0)
            end
            if purchased then
                if not partial then ranks = node.maxRanks end
                if not ranks or ranks < 1 or ranks > node.maxRanks or
                    (partial and ranks == node.maxRanks) then
                    error("TALENT_STRING_INVALID", 0)
                end
                local selection = node.type == Enum.TraitNodeType.Selection or
                    node.type == Enum.TraitNodeType.SubTreeSelection
                if choice ~= selection then error("TALENT_STRING_INVALID", 0) end
            end
            if node.type == Enum.TraitNodeType.Tiered then
                local remaining = ranks
                for index, entryID in ipairs(node.entryIDs) do
                    local info = C_Traits.GetEntryInfo(configID, entryID)
                    if not info or not info.maxRanks then error("TALENT_TREE_UNAVAILABLE", 0) end
                    local count = math.min(remaining, info.maxRanks)
                    local granted = not purchased and index == 1
                    if count > 0 or granted then
                        entries[#entries + 1] = {
                            nodeID = nodeID, selectionEntryID = entryID,
                            ranksPurchased = count, ranksGranted = granted and 1 or 0,
                        }
                    end
                    remaining = remaining - count
                end
                if remaining ~= 0 then error("TALENT_STRING_INVALID", 0) end
            else
                local entryID = choice and node.entryIDs[choiceIndex] or
                    (node.activeEntry and node.activeEntry.entryID) or node.entryIDs[1]
                -- An out-of-range encoded choice must not fall back to a different talent.
                if choice and not node.entryIDs[choiceIndex] then error("TALENT_STRING_INVALID", 0) end
                entries[#entries + 1] = {
                    nodeID = nodeID, selectionEntryID = entryID,
                    ranksPurchased = ranks, ranksGranted = purchased and 0 or 1,
                }
            end
        end
    end
    finish()
    return entries
end

local fallback = {
    TALENT_STRING_INVALID = "The talent import string is invalid or incomplete.",
    TALENT_STRING_VERSION = "This talent import format is outdated. Save the build again.",
    TALENT_STRING_SPEC = "The talent import string belongs to another specialization.",
    TALENT_STRING_TREE = "The talent tree has changed. Save the build again.",
    TALENT_TREE_UNAVAILABLE = "Talent tree data is not available. Try again once talents are ready.",
}

function ns.TalentImport:Decode(text, configID, specID)
    local ok, result = pcall(decode, text, configID, specID)
    if ok then return result end
    if not fallback[result] then ns.Log:Debug("Talent decoding error: " .. tostring(result)) end
    local key = fallback[result] and result or "TALENT_STRING_INVALID"
    return nil, L[key] or fallback[key]
end
