local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObstacleState = require(ReplicatedStorage.Shared.Classes.Obstacles.Domain.ObstacleState)

local ObstacleEntity = {}
ObstacleEntity.__index = ObstacleEntity

function ObstacleEntity.new(id: string, basePart: BasePart)
	local self = setmetatable({}, ObstacleEntity)

	self.Id = id
	self.BasePart = basePart
	self.State = ObstacleState.VISIBLE
	self.ActiveDuration = 0
	self.InactiveDuration = 0
	self.CurrentTimer = 0
	self.Transparency = basePart.Transparency

	return self
end

function ObstacleEntity:Update(dt: number)
	self.CurrentTimer = self.CurrentTimer + dt

	if self.State == ObstacleState.VISIBLE then
		if self.CurrentTimer >= self.ActiveDuration then
			self:Hide()
		end
	elseif self.State == ObstacleState.INVISIBLE then
		if self.CurrentTimer >= self.InactiveDuration then
			self:Show()
		end
	end
end

function ObstacleEntity:Hide()
	self.State = ObstacleState.INVISIBLE
	self.Transparency = 1
	self.CurrentTimer = 0
end

function ObstacleEntity:Show()
	self.State = ObstacleState.VISIBLE
	self.Transparency = 0
	self.CurrentTimer = 0
end

function ObstacleEntity:Reset()
	self.State = ObstacleState.VISIBLE
	self:SetRandomTimers()
end

function ObstacleEntity:SetRandomTimers()
	self.ActiveDuration = math.random(3, 4)
	self.InactiveDuration = math.random(2, 3)
	self.CurrentTimer = 0
end

function ObstacleEntity:GetObstacle()
	return self
end

return ObstacleEntity
