--[[
    LoggerController.lua
    Knit Controller: Client-side logging controller
    Follows Dependency Inversion Principle - depends on abstractions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local LogRepository = require(ReplicatedStorage.Shared.Classes.Logger.Repository.LogRepository)
local LogUseCase = require(ReplicatedStorage.Shared.Classes.Logger.Usecases.LogUsecase)
local ConsoleLogWriter = require(ReplicatedStorage.Shared.Classes.Logger.Implementation.Writers.ConsoleLogWriter)
local LevelLogFilter = require(ReplicatedStorage.Shared.Classes.Logger.Implementation.Filters.LevelLogFilter)
local LogLevel = require(ReplicatedStorage.Shared.Classes.Logger.Entities.LogLevel)

local LoggerController = Knit.CreateController({
	Name = "LoggerController",
})

function LoggerController:KnitInit()
	self.repository = LogRepository.new()
	self.repository:AddWriter(ConsoleLogWriter.new())
	self.repository:AddFilter(LevelLogFilter.new(LogLevel.INFO))

	self.useCase = LogUseCase.new(self.repository)

	self.LoggerService = nil

	self.sendToServer = true -- Whether to send logs to server
	self.sendThreshold = LogLevel.WARN -- Only send WARN and above to server

	print("[LoggerController] Initialized")
end

function LoggerController:KnitStart()
	self.LoggerService = Knit.GetService("LoggerService")

	print("[LoggerController] Started")
end

-- Private helper to send to server if needed
function LoggerController:_SendToServer(level: number, message: string, context: string?, metadata: { [string]: any }?)
	if not self.sendToServer then
		return
	end

	if level < self.sendThreshold then
		return
	end

	if self.LoggerService then
		local success, err = pcall(function()
			self.LoggerService.LogToServer:Fire(level, message, context, metadata)
		end)

		if not success then
			warn("[LoggerController] Failed to send log to server:", err)
		end
	end
end

-- Public API
function LoggerController:Debug(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Debug(message, context, metadata)
	self:_SendToServer(LogLevel.DEBUG, message, context, metadata)
end

function LoggerController:Info(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Info(message, context, metadata)
	self:_SendToServer(LogLevel.INFO, message, context, metadata)
end

function LoggerController:Warn(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Warn(message, context, metadata)
	self:_SendToServer(LogLevel.WARN, message, context, metadata)
end

function LoggerController:Error(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Error(message, context, metadata)
	self:_SendToServer(LogLevel.ERROR, message, context, metadata)
end

function LoggerController:Fatal(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Fatal(message, context, metadata)
	self:_SendToServer(LogLevel.FATAL, message, context, metadata)
end

-- Configuration methods
function LoggerController:SetSendToServer(enabled: boolean)
	self.sendToServer = enabled
end

function LoggerController:SetSendThreshold(level: number)
	self.sendThreshold = level
end

function LoggerController:SetMinLogLevel(level: number)
	for _, filter in ipairs(self.repository:GetFilters()) do
		if filter.minLevel then
			self.repository:RemoveFilter(filter)
		end
	end
	self.repository:AddFilter(LevelLogFilter.new(level))
end

-- Query methods (local only)
function LoggerController:GetRecentLogs(count: number?)
	return self.useCase:GetRecentLogs(count)
end

return LoggerController
