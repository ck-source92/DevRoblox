--[[
    LoggerService.lua
    Knit Service: Server-side logging service
    Follows Open/Closed Principle - extensible via writers and filters
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local LogRepository = require(ReplicatedStorage.Shared.Classes.Logger.Repository.LogRepository)
local LogUseCase = require(ReplicatedStorage.Shared.Classes.Logger.Usecases.LogUsecase)
local ConsoleLogWriter = require(ReplicatedStorage.Shared.Classes.Logger.Implementation.Writers.ConsoleLogWriter)
local DataStoreLogWriter = require(ReplicatedStorage.Shared.Classes.Logger.Implementation.Writers.DataStoreLogWriter)
local LevelLogFilter = require(ReplicatedStorage.Shared.Classes.Logger.Implementation.Filters.LevelLogFilter)
local LogLevel = require(ReplicatedStorage.Shared.Classes.Logger.Entities.LogLevel)

local LoggerService = Knit.CreateService({
	Name = "LoggerService",
	Client = {
		LogToServer = Knit.CreateSignal(),
	},
})

function LoggerService:KnitInit()
	self.repository = LogRepository.new()

	self.repository:AddWriter(ConsoleLogWriter.new())

	if game:GetService("RunService"):IsStudio() == false then
		self.repository:AddWriter(DataStoreLogWriter.new("GameLogs"))
	end

	self.repository:AddFilter(LevelLogFilter.new(LogLevel.INFO))

	self.useCase = LogUseCase.new(self.repository)

	print("[LoggerService] Initialized")
end

function LoggerService:KnitStart()
	self.Client.LogToServer:Connect(function(player, level, message, context, metadata)
		local enrichedMetadata = metadata or {}
		enrichedMetadata.PlayerId = player.UserId
		enrichedMetadata.PlayerName = player.Name

		self.useCase:Log(level, message, context or "Client", enrichedMetadata)
	end)

	task.spawn(function()
		while true do
			task.wait(60) -- Flush every minute
			self.useCase:Flush()
		end
	end)

	print("[LoggerService] Started")
end

-- Public API
function LoggerService:Debug(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Debug(message, context, metadata)
end

function LoggerService:Info(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Info(message, context, metadata)
end

function LoggerService:Warn(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Warn(message, context, metadata)
end

function LoggerService:Error(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Error(message, context, metadata)
end

function LoggerService:Fatal(message: string, context: string?, metadata: { [string]: any }?)
	self.useCase:Fatal(message, context, metadata)
end

-- Configuration methods
function LoggerService:AddWriter(writer)
	self.repository:AddWriter(writer)
end

function LoggerService:AddFilter(filter)
	self.repository:AddFilter(filter)
end

function LoggerService:SetMinLogLevel(level: number)
	-- Remove existing level filters and add new one
	for _, filter in ipairs(self.repository:GetFilters()) do
		if filter.minLevel then
			self.repository:RemoveFilter(filter)
		end
	end
	self.repository:AddFilter(LevelLogFilter.new(level))
end

-- Query methods
function LoggerService:GetRecentLogs(count: number?)
	return self.useCase:GetRecentLogs(count)
end

function LoggerService:GetLogsByLevel(level: number)
	return self.useCase:GetLogsByLevel(level)
end

function LoggerService:GetLogsByContext(context: string)
	return self.useCase:GetLogsByContext(context)
end

return LoggerService
