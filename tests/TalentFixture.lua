-- An independent encoder for the documented Retail bit format, not a mock decoder.
return function(T, fixture, locale)
    local env, ns, s, load = fixture(T, locale)
    env.Enum = { TraitNodeType = { Single = 0, Selection = 1, Tiered = 2, SubTreeSelection = 3 } }
    local types = env.Enum.TraitNodeType
    s.treeHash = {}
    for i = 1, 16 do s.treeHash[i] = 9 end
    s.nodes = {
        [10] = { maxRanks = 1, type = types.Single, entryIDs = { 101 } },
        [20] = { maxRanks = 1, type = types.Selection, entryIDs = { 201, 202 } },
        [30] = { maxRanks = 3, type = types.Single, entryIDs = { 301 } },
        [40] = { maxRanks = 1, type = types.SubTreeSelection, entryIDs = { 401, 402 } },
        [50] = { maxRanks = 3, type = types.Tiered, entryIDs = { 501, 502 } },
        [60] = { maxRanks = 1, type = types.Single, entryIDs = { 601 } },
    }
    s.configIDs[102] = { 10 }
    s.configs[10] = { name = "Raid", treeIDs = { 9000 } }
    s.flags = {}
    env.C_ClassTalents.GetActiveConfigID = function() return 10 end
    env.C_ClassTalents.GetTraitTreeForSpec = function() return 9000 end
    env.C_ClassTalents.SetUsesSharedActionBars = function(id, value)
        table.insert(s.flags, { id, value })
    end
    env.C_Traits.GetLoadoutSerializationVersion = function() return 2 end
    env.C_Traits.GetTreeHash = function() return s.treeHash end
    env.C_Traits.GetTreeNodes = function() return { 10, 20, 30, 40, 50, 60 } end
    env.C_Traits.GetNodeInfo = function(_, nodeID) return s.nodes[nodeID] end
    env.C_Traits.GetEntryInfo = function(_, entryID)
        return { maxRanks = entryID == 501 and 1 or 2 }
    end
    local import = env.C_ClassTalents.ImportLoadout
    env.C_ClassTalents.ImportLoadout = function(...)
        local ok, err = import(...)
        if s.importError then return false, s.importError end
        return ok, err
    end
    function s:encode(options)
        options = options or {}
        local bits = {}
        local function write(width, value)
            for i = 0, width - 1 do bits[#bits + 1] = math.floor(value / 2 ^ i) % 2 end
        end
        write(8, options.version or 2)
        write(16, options.spec or 102)
        for i = 1, 16 do write(8, options.hash and options.hash[i] or 9) end
        local selections = options.selections or {
            { granted = true }, { choice = 2 }, { ranks = 2 }, { choice = 2 }, { ranks = 2 }, false,
        }
        for i = 1, 6 do
            local selection = selections[i]
            write(1, selection and 1 or 0)
            if selection then
                write(1, selection.granted and 0 or 1)
                if not selection.granted then
                    write(1, selection.ranks ~= nil and 1 or 0)
                    if selection.ranks ~= nil then write(6, selection.ranks) end
                    write(1, selection.choice and 1 or 0)
                    if selection.choice then write(2, selection.choice - 1) end
                end
            end
        end
        if options.truncate then
            while #bits > options.truncate do table.remove(bits) end
        end
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local result = {}
        for i = 1, #bits, 6 do
            local value = 0
            for j = 0, 5 do value = value + (bits[i + j] or 0) * 2 ^ j end
            result[#result + 1] = chars:sub(value + 1, value + 1)
        end
        return table.concat(result)
    end
    function s:backup(text)
        env.RuilhennDB.talents = { DRUID = { [1] = {
            { name = "Raid", importString = text or self:encode(), usesSharedActionBars = false },
        } } }
    end
    load("TalentImport.lua")
    load("TalentManager.lua")
    return env, ns, s, load
end
