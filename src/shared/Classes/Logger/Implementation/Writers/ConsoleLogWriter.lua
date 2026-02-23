local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogLevel = require(ReplicatedStorage.Shared.Classes.Logger.Entities.LogLevel)

local ConsoleLogWriter = {}
ConsoleLogWriter.__index = ConsoleLogWriter

function ConsoleLogWriter.new()
	local self = setmetatable({}, ConsoleLogWriter)
	return self
end

function ConsoleLogWriter:Write(logEntry)
	-- Validate logEntry
	if not logEntry or type(logEntry) ~= "table" then
		warn("[ConsoleLogWriter] Invalid log entry received")
		return
	end

	local timestamp
	if type(logEntry.GetFormattedTimestamp) == "function" then
		timestamp = logEntry:GetFormattedTimestamp()
	elseif logEntry.timestamp then
		timestamp = os.date("%Y-%m-%d %H:%M:%S", logEntry.timestamp)
	else
		timestamp = os.date("%Y-%m-%d %H:%M:%S")
	end

	local levelName = LogLevel.Names[logEntry.level] or tostring(logEntry.level) or "UNKNOWN"
	local formattedMessage = string.format(
		"[%s] [%s]%s %s",
		timestamp,
		levelName,
		logEntry.context and (" [" .. logEntry.context .. "]") or "",
		logEntry.message or "No message"
	)

	-- Use appropriate output function based on log level
	if logEntry.level == LogLevel.ERROR or logEntry.level == LogLevel.FATAL then
		warn(formattedMessage)
		if logEntry.metadata then
			warn("Metadata:", logEntry.metadata)
		end
	elseif logEntry.level == LogLevel.WARN then
		warn(formattedMessage)
	else
		print(formattedMessage)
	end
end

function ConsoleLogWriter:Flush()
	-- Console doesn't need flushing
end

function ConsoleLogWriter:Close()
	-- Console doesn't require closing
end

return ConsoleLogWriter
