--[[
    LevelLogFilter.lua
    Implementation: Filters logs based on minimum log level
    Follows Dependency Inversion Principle by implementing ILogFilter
]]

local LevelLogFilter = {}
LevelLogFilter.__index = LevelLogFilter

function LevelLogFilter.new(minLevel: number)
	local self = setmetatable({}, LevelLogFilter)
	self.minLevel = minLevel
	return self
end

function LevelLogFilter:ShouldLog(logEntry): boolean
	return logEntry.level >= self.minLevel
end

function LevelLogFilter:SetMinLevel(level: number)
	self.minLevel = level
end

return LevelLogFilter
