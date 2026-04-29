local RS = game:GetService("ReplicatedStorage")

local Knit = require(RS.Packages.Knit)

local GameEvents = require(RS.Shared.Classes.Soccer.Events.GameEvents)
-- local PlayerEntity = require(RS.Shared.Classes.Soccer.PlayerEntity)
local Stats = require(RS.Shared.Classes.Soccer.ValueObjects.Stats)
local GameSession = require(RS.Shared.Classes.Soccer.Services.GameSession)

local GameService = Knit.CreateService({
	Name = "GameService",
	Client = {
		OnCountdown = Knit.CreateSignal(), -- (timeLeft)
		OnGameStart = Knit.CreateSignal(), -- ()
		OnDodgeResult = Knit.CreateSignal(), -- (success)
		OnGameOver = Knit.CreateSignal(), -- ()
		OnWin = Knit.CreateSignal(), -- (kickTargetPos)
	},
})

-- Config
local CONFIG = {
	COUNTDOWN_DURATION = 3, -- detik
	GAMEOVER_DELAY = 2, -- jeda sebelum screen muncul
	PLAYER_SPAWN_POS = Vector3.new(0, 3, -55),
	FIELD = {
		start = 0,
		finish = 200,
		width = 60,
	},
	DEFAULT_SKILL = 50,
	DEFAULT_SPEED = 16,
}

local sessions = {}

function GameService:OnPlayerEnterDoor(player)
	if sessions[player.UserId] then
		warn("Player sudah punya session aktif:", player.Name)
		return
	end

	local session = GameSession.new(player.UserId, CONFIG.DEFAULT_SKILL, CONFIG.DEFAULT_SPEED)
	sessions[player.UserId] = session

	self:_SpawnPlayerAtField(player, session)

	self:_StartCountdown(player, session)
end

function GameService:_SpawnPlayerAtField(player, session)
	local char = player.Character or player.CharacterAdded:Wait()
	char.Humanoid.WalkSpeed = session.player.stats.speed
	char:PivotTo(CFrame.new(CONFIG.PLAYER_SPAWN_POS))

	session:BeginCountdown()
	GameEvents.PlayerSpawned:Fire(player.UserId, CONFIG.PLAYER_SPAWN_POS)
end

function GameService:_StartCountdown(player, session)
	local duration = CONFIG.COUNTDOWN_DURATION

	GameEvents.CountdownStarted:Fire(player.UserId, duration)

	task.spawn(function()
		for i = duration, 1, -1 do
			self.Client.OnCountdown:Fire(player, i)
			task.wait(1)
		end

		self:_StartGame(player, session)
	end)
end

function GameService:_StartGame(player, session)
	session:StartGame()

	local NPCServiceV2 = Knit.GetService("NPCServiceV2")
	NPCServiceV2:SpawnForSession(player.UserId, CONFIG.FIELD)

	NPCServiceV2:StartAILoop(player.UserId, player)

	self:_SetupFinishLineTrigger(player, session)

	self.Client.OnGameStart:Fire(player)
end

function GameService.Client:AttemptDodge(player, obstacleSkill)
	local session = sessions[player.UserId]
	if not session or not session:IsRunning() then
		return
	end

	local obstacleStats = Stats.new(obstacleSkill, 0)
	local success = session.player:TryDodge(obstacleStats)

	self.Server.Client.OnDodgeResult:Fire(player, success)
end

function GameService:_HandleGameOver(userId)
	local session = sessions[userId]
	local player = game.Players:GetPlayerByUserId(userId)
	if not session or not player then
		return
	end

	session:TriggerGameOver()

	player.Character.Humanoid.WalkSpeed = 0

	task.delay(CONFIG.GAMEOVER_DELAY, function()
		self.Client.OnGameOver:Fire(player)
		self:_CleanupSession(userId)
	end)
end

function GameService:_SetupFinishLineTrigger(player, session)
	local finishLine = workspace:FindFirstChild("FinishLine")
	if not finishLine then
		return
	end

	local connection
	connection = finishLine.Touched:Connect(function(hit)
		local char = player.Character
		if not char or not hit:IsDescendantOf(char) then
			return
		end
		if not session:IsRunning() then
			return
		end

		connection:Disconnect() -- satu kali saja

		session.player:ReachFinishLine()
	end)
end

function GameService:_HandleFinishLine(userId)
	local session = sessions[userId]
	local player = game.Players:GetPlayerByUserId(userId)
	if not session or not player then
		return
	end

	session:TriggerWin()

	player.Character.Humanoid.WalkSpeed = 0

	-- Kick ball
	local BallService = Knit.GetService("BallService")
	local kickTarget = BallService:KickToGoal(userId)

	self.Client.OnWin:Fire(player, kickTarget)

	task.delay(3, function()
		self:_CleanupSession(userId)
	end)
end

function GameService:_CleanupSession(userId)
	local session = sessions[userId]
	if not session then
		return
	end

	session:Cleanup()

	local NPCServiceV2 = Knit.GetService("NPCServiceV2")
	NPCServiceV2:ClearSession(userId)

	sessions[userId] = nil

	GameEvents.SessionCleaned:Fire(userId)
end

function GameService:KnitStart()
	GameEvents.PlayerDefeated:Connect(function(userId)
		self:_HandleGameOver(userId)
	end)

	GameEvents.FinishLineReached:Connect(function(userId)
		self:_HandleFinishLine(userId)
	end)

	game.Players.PlayerRemoving:Connect(function(player)
		self:_CleanupSession(player.UserId)
	end)
end

return GameService
