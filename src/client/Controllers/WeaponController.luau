-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer
local WeaponService = nil
-- TemplateController
local WeaponController = Knit.CreateController({
	Name = "TemplateController",
})

--|| Local Functions ||--

--|| Functions ||--

--|| Knit Lifecycle ||--
function WeaponController:KnitInit()
	WeaponService = Knit.GetService("WeaponService")
end
function WeaponController:KnitStart()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			WeaponService:ToggleSword()
		end
	end)
end

return WeaponController
