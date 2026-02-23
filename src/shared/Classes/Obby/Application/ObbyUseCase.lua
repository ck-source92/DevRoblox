local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

local ObbyUseCase = {}
ObbyUseCase.__index = ObbyUseCase

function ObbyUseCase.new(ObbyRepository, RbxObbyService)
	local self = setmetatable({}, ObbyUseCase)

	self.ObbyRepository = ObbyRepository
	self.RbxObbyService = RbxObbyService

	return self
end

function ObbyUseCase:Execute()
	local obstacleParts = self.RbxObbyService:FindObstacles()
	local initializedCount = 0

	for _, part in ipairs(obstacleParts) do
		local obstacle = self:CreateObstacle(part)
		self:InitializeObstacle(obstacle)
		initializedCount += 1
	end

	return true, string.format("Initialized %d obstacles", initializedCount)
end

function ObbyUseCase:CreateObstacle(part: BasePart)
	local obstacleId = self:GenerateObstacleId()
	local obbyType = self:DetermineObbyType(part)
	local ObbyEntityClass = self:GetObbyEntityClass(obbyType)

	return ObbyEntityClass.new(obstacleId, part)
end

function ObbyUseCase:GenerateObstacleId(): string
	local currentCount = #self.ObbyRepository:GetAll() + 1
	return "Obstacle_" .. currentCount
end

function ObbyUseCase:DetermineObbyType(part: BasePart): number?
	local obbyType = part:GetAttribute("ObbyType")

	if not obbyType then
		if part.Name == "Obstacle1" or part.Name == "Obstacle3" then
			obbyType = ObbyData.ObbyType.SEQUENCE
		elseif part:IsDescendantOf(workspace.Lobby.Environment.Obby.Obstacle2) then
			obbyType = ObbyData.ObbyType.MOVING
		end
	end

	return obbyType
end

function ObbyUseCase:GetObbyEntityClass(obbyType: number?)
	if obbyType == ObbyData.ObbyType.MOVING then
		return require(ReplicatedStorage.Shared.Classes.Obby.Domain.MovingObbyEntity)
	elseif obbyType == ObbyData.ObbyType.SEQUENCE then
		return require(ReplicatedStorage.Shared.Classes.Obby.Domain.SequenceObbyEntity)
	elseif obbyType == ObbyData.ObbyType.LASER_VERTICAL then
		return require(ReplicatedStorage.Shared.Classes.Obby.Domain.LaserVerticalEntity)
	elseif obbyType == ObbyData.ObbyType.LASER_HORIZONTAL then
		return require(ReplicatedStorage.Shared.Classes.Obby.Domain.LaserHorizontalEntity)
	else
		return require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyEntity)
	end
end

function ObbyUseCase:InitializeObstacle(obstacle)
	obstacle:SetRandomTimers()
	self.ObbyRepository:Save(obstacle)
end

return ObbyUseCase
