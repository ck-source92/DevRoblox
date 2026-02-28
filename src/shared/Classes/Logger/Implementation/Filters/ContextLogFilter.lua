--[[
    ContextLogFilter.lua
    Implementation: Filters logs based on context (e.g., specific module or system)
    Follows Dependency Inversion Principle by implementing ILogFilter
]]

local ContextLogFilter = {}
ContextLogFilter.__index = ContextLogFilter

function ContextLogFilter.new(allowedContexts: { string })
	local self = setmetatable({}, ContextLogFilter)

	-- Convert array to set for O(1) lookup
	self.allowedContexts = {}
	for _, context in ipairs(allowedContexts) do
		self.allowedContexts[context] = true
	end

	return self
end

function ContextLogFilter:ShouldLog(logEntry): boolean
	if not logEntry.context then
		return true
	end

	return self.allowedContexts[logEntry.context] ~= nil
end

function ContextLogFilter:AddContext(context: string)
	self.allowedContexts[context] = true
end

function ContextLogFilter:RemoveContext(context: string)
	self.allowedContexts[context] = nil
end

return ContextLogFilter
