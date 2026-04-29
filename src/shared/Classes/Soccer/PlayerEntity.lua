local RS = game:GetService("ReplicatedStorage")

local Stats = require(RS.Shared.Classes.Soccer.ValueObjects.Stats)
local GameEvents = require(RS.Shared.Classes.Soccer.Events.GameEvents)

local PlayerEntity = {}
PlayerEntity.__index = PlayerEntity

function PlayerEntity.new(userId, skill, speed)
	return setmetatable({
		userId = userId,
		stats = Stats.new(skill, speed),
		isDodging = false,
		isAlive = true,
	}, PlayerEntity)
end

function PlayerEntity:TryDodge(obstacleStats)
	local success = self.stats.skill >= obstacleStats.skill

	GameEvents.DodgeAttempted:Fire(self.userId, success)

	if not success then
		self:Defeat()
	end

	return success
end

function PlayerEntity:Defeat()
	self.isAlive = false
	GameEvents.PlayerDefeated:Fire(self.userId)
end

function PlayerEntity:ReachFinishLine()
	GameEvents.FinishLineReached:Fire(self.userId)
end

return PlayerEntity
