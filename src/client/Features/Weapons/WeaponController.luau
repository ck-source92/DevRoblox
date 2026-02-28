--!strict
-- Features/Weapons/WeaponController.luau
-- Handles user input for the Weapons feature.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local WeaponController = Knit.CreateController({
	Name = "WeaponController",
})

function WeaponController:KnitStart()
	local WeaponService = Knit.GetService("WeaponService")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			WeaponService:ToggleSword()
		end
	end)
end

return WeaponController
