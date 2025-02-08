-- TaskQueue.lua
local _, ns = ...
local TaskQueue = {}
ns.TaskQueue = TaskQueue

-- WoW API
local CreateFrame = CreateFrame
local GetFramerate = GetFramerate

function TaskQueue:New(initialTasksPerFrame)
    local queue = {
        tasks = {},
        tasksPerFrame = initialTasksPerFrame or 5,
        taskFrame = CreateFrame("Frame", "RuilhennTaskFrame")
    }
    
    setmetatable(queue, { __index = TaskQueue })
    return queue
end

function TaskQueue:AddTask(task)
    table.insert(self.tasks, task)
end

function TaskQueue:Process()
    local tasksProcessed = 0
    while tasksProcessed < self.tasksPerFrame and #self.tasks > 0 do
        local task = table.remove(self.tasks, 1)
        local success, err = pcall(task)
        if not success then
            ns.Log:Error(ns.L["TASKS_ERROR"]:format(err))
        end
        tasksProcessed = tasksProcessed + 1
    end
    if #self.tasks == 0 then
        self.taskFrame:SetScript("OnUpdate", nil)
        ns.Log:Debug(ns.L["TASKS_PROCESSED"])
    end
end

function TaskQueue:Run()
    if #self.tasks > 0 then
        self.taskFrame:SetScript("OnUpdate", function()
            local fps = GetFramerate()
            self.tasksPerFrame = math.max(1, math.floor(fps / 10))
            self:Process()
        end)
    end
end
