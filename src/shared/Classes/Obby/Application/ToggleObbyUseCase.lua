local ObbyData = require(game:GetService("ReplicatedStorage").Shared.Classes.Obby.Domain.ObbyData)

local ToggleObbyUseCase = {}
ToggleObbyUseCase.__index = ToggleObbyUseCase

function ToggleObbyUseCase.new(obstacleRepository)
	local self = setmetatable({}, ToggleObbyUseCase)

	self.ObstacleRepository = obstacleRepository

	return self
end

function ToggleObbyUseCase:Execute(obstacleId: string)
	local obstacle = self.ObstacleRepository:GetById(obstacleId)
	if not obstacle then
		return false, "Obstacle not found"
	end

	if obstacle.State == ObbyData.ObbyState.INVISIBLE then
		obstacle:Show()
	else
		obstacle:Hide()
	end

	self.ObstacleRepository:Save(obstacle)

	return true, "Obstacle state changed", obstacle
end

return ToggleObbyUseCase
