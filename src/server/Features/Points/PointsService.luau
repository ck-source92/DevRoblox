--!strict
-- Features/Points/PointsService.luau
-- Application Service for Points. Coordinates Domain and Infra.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PointsRepository = require(script.Parent.PointsRepository)
local Wallet = require(ReplicatedStorage.Shared.Features.Points.Domain.Wallet)

local PointsService = Knit.CreateService({
	Name = "PointsService",
	Client = {
		PointsChanged = Knit.CreateSignal(), -- (newPoints) with delta if needed
	},
})

function PointsService:KnitInit()
	self._repo = PointsRepository.new()
	self._wallets = {} -- [Player] = Wallet
end

function PointsService:KnitStart()
	-- Player Lifecycle
	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoved(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_onPlayerAdded(player)
		end)
	end
end

function PointsService:_onPlayerAdded(player: Player)
	local profile = self._repo:LoadProfile(player)
	if not profile then
		return
	end

	-- Initialize Domain Object from Data (Entity Rehydration)
	local wallet = Wallet.new(profile.Data.Points)
	self._wallets[player] = wallet

	print(("[PointsService] Loaded %s: %d points"):format(player.Name, wallet:Get()))

	-- Initial Replication
	self.Client.PointsChanged:Fire(player, wallet:Get())
end

function PointsService:_onPlayerRemoved(player: Player)
	local wallet = self._wallets[player]
	local profile = self._repo:GetProfile(player)

	if wallet and profile then
		-- Persist Domain State to Data
		profile.Data.Points = wallet:Get()
	end

	self._wallets[player] = nil
	self._repo:ReleaseProfile(player)
end

function PointsService:AddPoints(player: Player, amount: number)
	local wallet = self._wallets[player]
	if wallet then
		local newBalance = wallet:Add(amount)
		print(("[PointsService] Added %d to %s. New: %d"):format(amount, player.Name, newBalance))
		self.Client.PointsChanged:Fire(player, newBalance)
	else
		warn(("[PointsService] No wallet for %s"):format(player.Name))
	end
end

function PointsService:GetPoints(player: Player): number
	local wallet = self._wallets[player]
	return wallet and wallet:Get() or 0
end

-- Client Methods
function PointsService.Client:GetPoints(player: Player)
	return self.Server:GetPoints(player)
end

return PointsService
