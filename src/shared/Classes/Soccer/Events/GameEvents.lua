local Signal = require(game:GetService("ReplicatedStorage").Packages.Signal)

local GameEvents = {
	SessionStateChanged = Signal.new(), -- (userId, newState)
	PlayerSpawned = Signal.new(), -- (userId, position)
	CountdownStarted = Signal.new(), -- (userId, duration)

	NPCDetectedPlayer = Signal.new(), -- (npcId)
	NPCDespawned = Signal.new(), -- (npcId)
	DodgeAttempted = Signal.new(), -- (userId, success)
	PlayerDefeated = Signal.new(), -- (userId)
	FinishLineReached = Signal.new(), -- (userId)

	BallKicked = Signal.new(), -- (userId, targetPos)
	SessionCleaned = Signal.new(), -- (userId)
}

return GameEvents
