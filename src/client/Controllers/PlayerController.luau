local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Client = {},
})

function PlayerController.KnitStart()
	local PointService = Knit.GetService("PointService")
	local SpawnerService = Knit.GetService("SpawnerService")

	SpawnerService.CoinCollected:Connect(function(value)
		print("Coin Collected in value : ", value)
		PointService:AddPoint(value)
	end)
end

return PlayerController
