local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Sevices
local PointsService = nil

local PointController = Knit.CreateController({
	Name = "PointController",
})

function PointController.KnitStart()
	PointsService = Knit.GetService("PointService")

	-- -- Observer (listener)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			PointsService:GetPoints():andThen(PointsChanged)
			PointsService.PointsChanged:Connect(PointsChanged)
			PointsService:GiveMePoints(game.Players.LocalPlayer)
		end
	end)
end

return PointController
