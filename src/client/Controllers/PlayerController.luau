local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Client = {},
})

function PlayerController.KnitStart()
	local PushObjectServices = Knit.GetService("PushObjectServices")

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			print("[BoxController] E pressed, requesting stop pushing box")
			PushObjectServices:RequestStopPushing()
		end
	end)
end

return PlayerController
