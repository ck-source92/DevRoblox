-- Packages
local PointsService = game:GetService("PointsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

local PointService = Knit.CreateService({
	Name = "PointService",
	PointPerPlayer = {},
	PointsChanged = Signal.new(), -- Emitter
	GiveMePoints = Signal.new(), -- Emitter
	Client = {
		PointsChanged = Knit.CreateSignal(),
		GiveMePoints = Knit.CreateSignal(),
	},
})

function PointService:KnitInit()
	-- Listen for GiveMePoint signal internally (server-side observer)
	local rng = Random.new()

	-- Give player random amount of points:
	self.GiveMePoints:Connect(function(player)
		local points = rng:NextInteger(0, 10)
		self:AddPoint(player, points)
		print("Gave " .. player.Name .. " " .. points .. " points")
	end)
end

function PointService:KnitStart()
	-- Setup when player joins
	game.Players.PlayerAdded:Connect(function(player)
		self.PointPerPlayer[player] = 0
	end)
	-- Setup when player disconnect
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		self.PointsPerPlayer[player] = nil
	end)
end

function PointService:AddPoint(player: Player, amount)
	local points = self:GetPoints(player)
	points = points + amount
	self.PointPerPlayer[player] = points -- Store points
	print(("%s now has %d points"):format(player.Name, points))
	-- Fire signal/ Emit Event
	if amount ~= 0 then
		self.PointsChanged:Fire(player, points)
		self.Client.PointsChanged:Fire(player, points)
	end
end

function PointService.Client:AddPoint(player: Player, amount)
	self.Server:AddPoint(player, amount)
end

-- Client can request points through GiveMePoints signal
function PointService.Client:GiveMePoints(player: Player, amount: number)
	self.Server.GiveMePoints:Fire(player, amount)
end

function PointService:GetPoints(player: Player)
	local points = self.PointPerPlayer[player]
	return if points ~= nil then points else 0
end

function PointService.Client:GetPoints(player: Player)
	self.Server:GetPoints(player)
end

return PointsService
