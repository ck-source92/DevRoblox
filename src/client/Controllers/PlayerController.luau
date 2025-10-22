local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Client = {},
})

function PlayerController.KnitStart() end

return PlayerController
