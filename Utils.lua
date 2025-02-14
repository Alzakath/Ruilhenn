-- Utils.lua
local _, ns = ...
local Utils = ns.Utils

function Utils:DumpTable(value)
    if type(value) == 'table' then
        local s = '{ '
        for k, v in pairs(value) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. self:DumpTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(value)
    end
end

function Utils:SplitWhitespace(str)
    local words = {}
    for word in str:gmatch("%S+") do
        table.insert(words, word)
    end
    return words
end

function Utils:UnpackFirst(t)
    local first = table.remove(t, 1) -- Get the first element
    return first, t
end

function Utils:Map(func, list)
    local new_list = {}  -- Create a new table for results
    for i, v in ipairs(list) do
        new_list[i] = func(v)  -- Apply function to each element
    end
    return new_list
end
