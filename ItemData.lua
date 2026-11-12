local _, ns = ...
ns.ItemData = {}

-- Wait for the entire batch before the caller mutates macros or action bars.
function ns.ItemData:WithNames(ids, callback)
    local names, pending, requests = {}, {}, {}
    for _, id in ipairs(ids) do
        if not names[id] and not pending[id] then
            local name = C_Item.GetItemInfo(id)
            if name then
                names[id] = name
            else
                pending[id] = true
                requests[#requests + 1] = id
            end
        end
    end
    if #requests == 0 then callback(names); return end
    local frame, timer, done = CreateFrame("Frame"), nil, false
    local function finish(failedID)
        if done then return end
        done = true
        frame:UnregisterAllEvents()
        frame:SetScript("OnEvent", nil)
        if timer then timer:Cancel() end
        callback(not failedID and names or nil, failedID)
    end
    frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    frame:SetScript("OnEvent", function(_, _, id, success)
        if not pending[id] then return end
        local name = success and C_Item.GetItemInfo(id)
        if not name then finish(id); return end
        names[id], pending[id] = name, nil
        if not next(pending) then finish() end
    end)
    timer = C_Timer.NewTimer(15, function() finish(next(pending)) end)
    for _, id in ipairs(requests) do
        if done then break end
        local ok = pcall(C_Item.RequestLoadItemDataByID, id)
        if not ok then finish(id) end
    end
end
