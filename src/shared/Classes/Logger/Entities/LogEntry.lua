local LogEntry = {}
LogEntry.__index = LogEntry

export type LogEntry = {
	timestamp: number,
	level: number,
	message: string,
	context: string?,
	stackTrace: string?,
	metadata: { [string]: any }?,
}

function LogEntry.new(level: number, message: string, context: string?, metadata: { [string]: any }?): LogEntry
	local self = setmetatable({}, LogEntry)

	self.timestamp = os.time()
	self.level = level
	self.message = message
	self.context = context
	self.metadata = metadata
	self.stackTrace = debug.traceback("", 3) -- Skip LogEntry.new, Logger method, and Logger call

	return self
end

function LogEntry:GetFormattedTimestamp(): string
	return os.date("%Y-%m-%d %H:%M:%S", self.timestamp)
end

function LogEntry:ToString(): string
	local parts = {
		string.format("[%s]", self:GetFormattedTimestamp()),
		string.format("[%s]", self.level),
	}

	if self.context then
		table.insert(parts, string.format("[%s]", self.context))
	end

	table.insert(parts, self.message)

	if self.metadata then
		local metaStr = {}
		for key, value in pairs(self.metadata) do
			table.insert(metaStr, string.format("%s=%s", key, tostring(value)))
		end
		if #metaStr > 0 then
			table.insert(parts, string.format("{%s}", table.concat(metaStr, ", ")))
		end
	end

	return table.concat(parts, " ")
end

return LogEntry
