-- Packages
local PointsService = game:GetService("PointsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PointService = Knit.CreateService({
	Name = "PointService",
	PointPerPlayer = {},
	PointChanged = Signal.new(),
	Client = {
		PointChanged = Knit.CreateSignal(),
		-- GiveMePoints = Knit.CreateFunction()
	},
})

function PointService:Init()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self.PointsPerPlayer[player] = nil
	end)
end

function PointService:KnitStart()
	-- Setup when player joins
	game.Players.PlayerAdded:Connect(function(player)
		self.PointPerPlayer[player] = 0
	end)
end

function PointService:AddPoint(player: Player, amount)
	if typeof(amount) ~= "number" then
		warn("PointService:AddPoint - invalid amount from", player and player.Name, "got", typeof(amount), amount)
		return
	end

	local points = self:GetPoint(player)
	points = points + amount
	self.PointPerPlayer[player] = points -- Store points
	print(("%s now has %d points"):format(player.Name, points))
	-- Fire signal
	if amount ~= 0 then
		self.PointChanged:Fire(player, points)
	end
end

function PointService.Client:AddPoint(player: Player, amount)
	print("player", player.Name, "amount : ", amount)
	self.Server:AddPoint(player, amount)
end

function PointService:GetPoint(player: Player)
	local points = self.PointPerPlayer[player]
	return if points ~= nil then points else 0
end

function PointService.Client:GetPoint(player: Player)
	self.Server:GetPoint(player)
end

return PointsService
