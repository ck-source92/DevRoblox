-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Player
local player = Players.LocalPlayer

-- SpawnerController
local SpawnerController = Knit.CreateController({
	Name = "SpawnerController",
})

--|| Local Functions ||--

--|| Functions ||--

function SpawnerController:KnitStart()
	print("controller start")
	local SpawnerService = Knit.GetService("SpawnerService")

	UserInputService.InputBegan:Connect(function(input, update)
		if update then
			return
		end

		if input.KeyCode == Enum.KeyCode.F then
			SpawnerService:SpawnObject("PartCoin", Vector3.new(0, 5, 0))
		end
	end)
	print("controller finish ")
end

return SpawnerController
