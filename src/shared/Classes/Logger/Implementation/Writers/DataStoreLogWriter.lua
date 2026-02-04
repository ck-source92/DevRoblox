--[[
    DataStoreLogWriter.lua
    Implementation: Writes logs to Roblox DataStore for persistence
    Follows Dependency Inversion Principle by implementing ILogWriter
]]

local DataStoreService = game:GetService("DataStoreService")

local DataStoreLogWriter = {}
DataStoreLogWriter.__index = DataStoreLogWriter

function DataStoreLogWriter.new(dataStoreName: string?)
	local self = setmetatable({}, DataStoreLogWriter)

	self.dataStoreName = dataStoreName or "GameLogs"
	self.logStore = DataStoreService:GetDataStore(self.dataStoreName)
	self.buffer = {}
	self.maxBufferSize = 10 -- Flush after 10 entries

	return self
end

function DataStoreLogWriter:Write(logEntry)
	table.insert(self.buffer, {
		timestamp = logEntry.timestamp,
		level = logEntry.level,
		message = logEntry.message,
		context = logEntry.context,
		metadata = logEntry.metadata,
	})

	-- Auto-flush if buffer is full
	if #self.buffer >= self.maxBufferSize then
		self:Flush()
	end
end

function DataStoreLogWriter:Flush()
	if #self.buffer == 0 then
		return
	end

	local success, err = pcall(function()
		local key = "Logs_" .. os.time()
		self.logStore:SetAsync(key, self.buffer)
	end)

	if success then
		self.buffer = {}
	else
		warn("Failed to flush logs to DataStore:", err)
	end
end

function DataStoreLogWriter:Close()
	self:Flush()
end

return DataStoreLogWriter
