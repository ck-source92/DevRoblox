local RS = game:GetService("ReplicatedStorage")

local PlayerEntity = require(RS.Shared.Classes.Soccer.PlayerEntity)
local GameEvents = require(RS.Shared.Classes.Soccer.Events.GameEvents)
-- local NPCEntity = require(RS.Shared.Classes.Soccer.NPCEntity)
-- local FormationFactory = require(RS.Shared.Classes.Soccer.Services.FormationFactory)
-- local Stats = require(RS.Shared.Classes.Soccer.ValueObjects.Stats)

local GameSession = {}
GameSession.__index = GameSession

-- State yang valid
local States = {
	WAITING = "WAITING",
	COUNTDOWN = "COUNTDOWN",
	RUNNING = "RUNNING",
	GAMEOVER = "GAMEOVER",
	WIN = "WIN",
	CLEANUP = "CLEANUP",
}

local VALID_TRANSITIONS = {
	[States.WAITING] = { States.COUNTDOWN },
	[States.COUNTDOWN] = { States.RUNNING },
	[States.RUNNING] = { States.GAMEOVER, States.WIN },
	[States.GAMEOVER] = { States.CLEANUP },
	[States.WIN] = { States.CLEANUP },
	[States.CLEANUP] = {},
}

function GameSession.new(userId, skill, speed)
	return setmetatable({
		sessionId = userId,
		player = PlayerEntity.new(userId, skill, speed),
		npcs = {},
		status = States.WAITING,
		startTime = nil,
		npcFolder = nil,
	}, GameSession)
end

function GameSession:_TransitionTo(newState)
	local allowed = VALID_TRANSITIONS[self.status]

	for _, validState in ipairs(allowed) do
		if validState == newState then
			self.status = newState
			GameEvents.SessionStateChanged:Fire(self.sessionId, newState)
			return true
		end
	end

	warn(("[Session %s] Transisi INVALID: %s → %s"):format(self.sessionId, self.status, newState))
	return false
end

function GameSession:BeginCountdown()
	self:_TransitionTo(States.COUNTDOWN)
end

function GameSession:StartGame()
	if self:_TransitionTo(States.RUNNING) then
		self.startTime = os.clock()
	end
end

function GameSession:TriggerGameOver()
	self:_TransitionTo(States.GAMEOVER)
end

function GameSession:TriggerWin()
	self:_TransitionTo(States.WIN)
end

function GameSession:Cleanup()
	self:_TransitionTo(States.CLEANUP)

	-- Destroy semua NPC entity milik session ini
	for id, npc in pairs(self.npcs) do
		npc:Despawn()
	end
	self.npcs = {}
end

function GameSession:IsRunning()
	return self.status == States.RUNNING
end

function GameSession:GetElapsed()
	if not self.startTime then
		return 0
	end
	return os.clock() - self.startTime
end

return GameSession
