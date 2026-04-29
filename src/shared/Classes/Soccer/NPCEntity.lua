local RS = game:GetService("ReplicatedStorage")

local Stats = require(RS.Shared.Classes.Soccer.ValueObjects.Stats)
local GameEvents = require(RS.Shared.Classes.Soccer.Events.GameEvents)

local NPCEntity = {}
NPCEntity.__index = NPCEntity

local DETECT_RADIUS = 20

function NPCEntity.new(id, skill, speed, formationSlot)
	return setmetatable({
		id = id,
		stats = Stats.new(skill, speed),
		formationSlot = formationSlot,
		isActive = true,
		state = "IDLE", -- IDLE | CHASING | TACKLING | DESPAWNED
	}, NPCEntity)
end

function NPCEntity:CanDetectTarget(npcPosition, targetPosition)
	if not self.isActive then
		return false
	end
	local distance = (npcPosition - targetPosition).Magnitude
	return distance <= DETECT_RADIUS
end

function NPCEntity:StartChasing()
	self.state = "CHASING"
	GameEvents.NPCDetectedPlayer:Fire(self.id)
end

function NPCEntity:Despawn()
	self.isActive = false
	self.state = "DESPAWNED"
	GameEvents.NPCDespawned:Fire(self.id)
end

return NPCEntity
