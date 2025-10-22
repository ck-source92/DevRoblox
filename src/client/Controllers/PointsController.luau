local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PointController = Knit.CreateController({
	Name = "PointController",
})

local function PointsChanged(points)
	print("My points:", points)
end

function PointController.KnitStart()
	local PointsService = Knit.GetService("PointService")

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
