--!strict
-- Features/Points/PointsController.luau
-- Client logic for Points feature. Listens to Service and updates Store.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local PointsActions = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions.PointsActions)

local PointsController = Knit.CreateController({
	Name = "PointsController",
})

function PointsController:KnitStart()
	local PointsService = Knit.GetService("PointsService")

	-- Listen for replication
	PointsService.PointsChanged:Connect(function(newPoints: number)
		Store:dispatch(PointsActions.setPoints(newPoints))
	end)

	-- -- Observer (listener)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		-- Example: Debug key to request points (if allowed)
		-- if input.KeyCode == Enum.KeyCode.E then
		-- 	PointsService:GiveRandomPoints()
		-- end
	end)
end

return PointsController
