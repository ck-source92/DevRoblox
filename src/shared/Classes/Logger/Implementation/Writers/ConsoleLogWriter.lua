local LogLevel = require(script.Parent.LogLevel)

local ConsoleLogWriter = {}
ConsoleLogWriter.__index = ConsoleLogWriter

function ConsoleLogWriter.new()
	local self = setmetatable({}, ConsoleLogWriter)
	return self
end

function ConsoleLogWriter.Write(logEntry)
	local levelName = LogLevel.Names[logEntry.level] or "UNKNOWN"
	local formattedMessage = string.format(
		"[%s] [%s]%s %s",
		logEntry:GetFormattedTimestamp(),
		levelName,
		logEntry.context and (" [" .. logEntry.context .. "]") or "",
		logEntry.message
	)

	if levelName == LogLevel.ERROR or levelName == LogLevel.FATAL then
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
