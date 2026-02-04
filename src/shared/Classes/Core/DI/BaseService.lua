local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Logger = require(ReplicatedStorage.Shared.Classes.Logger.Logger)

local BaseService = {}
BaseService.__index = BaseService

function BaseService.new(name)
	local self = setmetatable({}, BaseService)

	self.Name = name
	self._dependencies = {}
	self._logger = Logger

	return self
end

function BaseService:AddDependency(serviceName)
	table.insert(self._dependencies, serviceName)
end

function BaseService:GetDependency(serviceName)
	return Knit.GetService(serviceName)
end

function BaseService:LogInfo(message)
	self._logger:Info(string.format("[%s] %s", self.Name, message))
end

function BaseService:LogError(message)
	self._logger:Error(string.format("[%s] %s", self.Name, message))
end

function BaseService:LogWarn(message)
	self._logger:Warn(string.format("[%s] %s", self.Name, message))
end

return BaseService
