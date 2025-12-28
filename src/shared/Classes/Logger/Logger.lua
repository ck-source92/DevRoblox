local Logger = {}
Logger.__index = Logger

function Logger.new()
	local self = setmetatable({}, Logger)
	self.enabled = true
	return self
end

function Logger:Info(message)
	if self.enabled then
		print(string.format("[INFO] %s", message))
	end
end

function Logger:Warn(message)
	if self.enabled then
		warn(string.format("[WARN] %s", message))
	end
end

function Logger:Error(message)
	if self.enabled then
		error(string.format("[ERROR] %s", message))
	end
end

return Logger.new()
