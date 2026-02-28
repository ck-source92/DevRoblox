--[[
    LogRepository.lua
    Repository: Manages log storage and retrieval operations
    Follows Single Responsibility Principle - only handles data access
]]

local LogRepository = {}
LogRepository.__index = LogRepository

function LogRepository.new()
	local self = setmetatable({}, LogRepository)

	self.writers = {}
	self.filters = {}
	self.logHistory = {} -- In-memory history
	self.maxHistorySize = 1000

	return self
end

-- Writer Management
function LogRepository:AddWriter(writer)
	table.insert(self.writers, writer)
end

function LogRepository:RemoveWriter(writer)
	for i, w in ipairs(self.writers) do
		if w == writer then
			table.remove(self.writers, i)
			break
		end
	end
end

function LogRepository:GetWriters()
	return self.writers
end

-- Filter Management
function LogRepository:AddFilter(filter)
	table.insert(self.filters, filter)
end

function LogRepository:RemoveFilter(filter)
	for i, f in ipairs(self.filters) do
		if f == filter then
			table.remove(self.filters, i)
			break
		end
	end
end

function LogRepository:GetFilters()
	return self.filters
end

-- Log Storage
function LogRepository:SaveLog(logEntry)
	-- Add to in-memory history
	table.insert(self.logHistory, logEntry)

	-- Trim history if too large
	if #self.logHistory > self.maxHistorySize then
		table.remove(self.logHistory, 1)
	end

	-- Apply filters
	for _, filter in ipairs(self.filters) do
		if not filter:ShouldLog(logEntry) then
			return -- Log filtered out
		end
	end

	-- Write to all writers
	for _, writer in ipairs(self.writers) do
		local success, err = pcall(function()
			writer:Write(logEntry)
		end)

		if not success then
			warn("LogWriter failed:", err)
		end
	end
end

-- Log Retrieval
function LogRepository:GetRecentLogs(count: number?): { any }
	count = count or 100
	local startIndex = math.max(1, #self.logHistory - count + 1)
	local logs = {}

	for i = startIndex, #self.logHistory do
		table.insert(logs, self.logHistory[i])
	end

	return logs
end

function LogRepository:GetLogsByLevel(level: number): { any }
	local logs = {}

	for _, log in ipairs(self.logHistory) do
		if log.level == level then
			table.insert(logs, log)
		end
	end

	return logs
end

function LogRepository:GetLogsByContext(context: string): { any }
	local logs = {}

	for _, log in ipairs(self.logHistory) do
		if log.context == context then
			table.insert(logs, log)
		end
	end

	return logs
end

function LogRepository:ClearHistory()
	self.logHistory = {}
end

-- Flush all writers
function LogRepository:FlushAll()
	for _, writer in ipairs(self.writers) do
		pcall(function()
			writer:Flush()
		end)
	end
end

return LogRepository
