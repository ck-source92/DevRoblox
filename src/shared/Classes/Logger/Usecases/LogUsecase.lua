--[[
    LogUseCase.lua
    Use Case: Contains business logic for logging operations
    Follows Single Responsibility Principle
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LogEntry = require(ReplicatedStorage.Shared.Classes.Logger.Entities.LogEntry)
local LogLevel = require(ReplicatedStorage.Shared.Classes.Logger.Entities.LogLevel)

local LogUseCase = {}
LogUseCase.__index = LogUseCase

function LogUseCase.new(repository)
	local self = setmetatable({}, LogUseCase)
	self.repository = repository
	return self
end

function LogUseCase:Log(level: number, message: string, context: string?, metadata: { [string]: any }?)
	-- Validate input
	if not message or message == "" then
		warn("Cannot log empty message")
		return
	end

	if not LogLevel.Names[level] then
		warn("Invalid log level:", level)
		return
	end

	-- Create log entry
	local logEntry = LogEntry.new(level, message, context, metadata)

	-- Save through repository
	self.repository:SaveLog(logEntry)
end

function LogUseCase:Debug(message: string, context: string?, metadata: { [string]: any }?)
	self:Log(LogLevel.DEBUG, message, context, metadata)
end

function LogUseCase:Info(message: string, context: string?, metadata: { [string]: any }?)
	self:Log(LogLevel.INFO, message, context, metadata)
end

function LogUseCase:Warn(message: string, context: string?, metadata: { [string]: any }?)
	self:Log(LogLevel.WARN, message, context, metadata)
end

function LogUseCase:Error(message: string, context: string?, metadata: { [string]: any }?)
	self:Log(LogLevel.ERROR, message, context, metadata)
end

function LogUseCase:Fatal(message: string, context: string?, metadata: { [string]: any }?)
	self:Log(LogLevel.FATAL, message, context, metadata)
end

-- Utility methods
function LogUseCase:GetRecentLogs(count: number?)
	return self.repository:GetRecentLogs(count)
end

function LogUseCase:GetLogsByLevel(level: number)
	return self.repository:GetLogsByLevel(level)
end

function LogUseCase:GetLogsByContext(context: string)
	return self.repository:GetLogsByContext(context)
end

function LogUseCase:ClearLogs()
	self.repository:ClearHistory()
end

function LogUseCase:Flush()
	self.repository:FlushAll()
end

return LogUseCase
