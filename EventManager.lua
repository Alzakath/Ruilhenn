local _, ns = ...
local EventManager = {}
ns.EventManager = EventManager

-- Dependencies
local TaskQueue = ns.TaskQueue
local Log = ns.Log

-- Singleton instance
local instance = nil

-- Default settings
local DEFAULT_EVENTS_PER_FRAME = 5

function EventManager:GetInstance(initialEventsPerFrame)
    if not instance then
        instance = self:New(initialEventsPerFrame or DEFAULT_EVENTS_PER_FRAME)
    end
    return instance
end

function EventManager:New(initialEventsPerFrame)
    local manager = {
        eventCallbacks = {},
        queue = TaskQueue:New(initialEventsPerFrame),
    }
    setmetatable(manager, { __index = EventManager })
    return manager
end

--- Registers a callback for a specific event.
-- @param eventName (string) Name of the event
-- @param callback (function) Function to call when the event is fired
function EventManager:RegisterEvent(eventName, callback)
    if not self.eventCallbacks[eventName] then
        self.eventCallbacks[eventName] = {}
    end
    table.insert(self.eventCallbacks[eventName], callback)
end

--- Fires an event, adding its callbacks to the task queue.
-- @param eventName (string) Name of the event
-- @param ... (any) Arguments to pass to callbacks
function EventManager:FireEvent(eventName, ...)
    local args = {...}
    local argCount = select("#", ...)
    self.queue:AddTask(function()
        if self.eventCallbacks[eventName] then
            for i, callback in ipairs(self.eventCallbacks[eventName]) do
                local success, err = pcall(callback, unpack(args, 1, argCount))
                if not success then
                    Log:Error(("EventManager: Error in callback for event '%s': %s"):format(eventName, tostring(err)))
                end
            end
        end
    end)
    self.queue:Run()
end

--- Returns the number of callbacks registered for an event.
-- @param eventName (string) Name of the event
-- @return (number) Number of callbacks
function EventManager:GetCallbackCount(eventName)
    if self.eventCallbacks[eventName] then
        return #self.eventCallbacks[eventName]
    end
    return 0
end

--- Returns a list of all registered events.
-- @return (table) List of event names
function EventManager:GetRegisteredEvents()
    local events = {}
    for eventName, _ in pairs(self.eventCallbacks) do
        table.insert(events, eventName)
    end
    return events
end
