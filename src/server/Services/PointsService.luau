-- PointsService.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PointsService = Knit.CreateService({
	Name = "PointsService",

	-- Server-only state (will be set in KnitInit)
	PointsPerPlayer = nil,
	_internalPointsChanged = nil,
	_rng = nil,

	-- Client-facing signals (Remote)
	Client = {
		PointsChanged = Knit.CreateSignal(), -- (player, newPoints, delta)
		GiveMePoints = Knit.CreateSignal(), -- debug only
	},
})

--//////////////////////////////
--// Lifecycle
--//////////////////////////////

function PointsService:KnitInit()
	self.PointsPerPlayer = {}
	self._internalPointsChanged = Signal.new()
	self._rng = Random.new()

	-- Internal observers (server-only listeners)
	self._internalPointsChanged:Connect(function(player, newPoints, delta)
		print(
			string.format(
				"[PointsService] Internal PointsChanged | player=%s delta=%d total=%d",
				player.Name,
				delta,
				newPoints
			)
		)
	end)
end

function PointsService:KnitStart()
	local function initPlayer(player: Player)
		-- Keep existing points if already set, otherwise 0
		local current = self.PointsPerPlayer[player]
		if current == nil then
			current = 0
		end
		self.PointsPerPlayer[player] = current

		print(string.format("[PointsService] Init player %s with %d points", player.Name, current))
	end

	-- Handle players already in the server when Knit starts
	for _, player in ipairs(Players:GetPlayers()) do
		initPlayer(player)
	end

	-- Handle future players
	Players.PlayerAdded:Connect(initPlayer)

	Players.PlayerRemoving:Connect(function(player)
		print(string.format("[PointsService] Removing player %s from table", player.Name))
		self.PointsPerPlayer[player] = nil
	end)
end

--//////////////////////////////
--// Core API
--//////////////////////////////

function PointsService:AddPoints(player: Player, amount: number)
	if not player or not player:IsA("Player") then
		warn("[PointsService] AddPoints called with invalid player:", player)
		return
	end

	if type(amount) ~= "number" then
		warn("[PointsService] AddPoints called with non-number amount:", amount)
		return
	end

	if amount == 0 then
		print(("[PointsService] AddPoints: %s amount is 0, ignoring"):format(player.Name))
		return
	end

	local oldPoints = self:GetPoints(player)
	local newPoints = oldPoints + amount
	self.PointsPerPlayer[player] = newPoints

	print(string.format("[PointsService] AddPoints: %s %+d (from %d to %d)", player.Name, amount, oldPoints, newPoints))

	-- Server-only signal
	self._internalPointsChanged:Fire(player, newPoints, amount)

	-- Notify client listeners
	self.Client.PointsChanged:Fire(player, newPoints, amount)
end

function PointsService:GetPoints(player: Player): number
	if not player or not player:IsA("Player") then
		warn("[PointsService] GetPoints called with invalid player:", player)
		return 0
	end

	local points = self.PointsPerPlayer[player]
	if points == nil then
		print(string.format("[PointsService] GetPoints: %s not initialized, returning 0", player.Name))
		return 0
	end

	return points
end

function PointsService.Client:GetPoints(player: Player)
	-- Player is the remote caller
	return self.Server:GetPoints(player)
end

-- Debug: client can request random points
-- Don't use this for real gameplay, just tooling / buttons.
function PointsService:GiveRandomPoints(player: Player)
	local amount = self._rng:NextInteger(0, 10)
	print(string.format("[PointsService] GiveRandomPoints: %s gets %d random points", player.Name, amount))
	self:AddPoints(player, amount)
end

function PointsService.Client:GiveRandomPoints(player: Player)
	-- Player is automatically the caller
	self.Server:GiveRandomPoints(player)
end

return PointsService
