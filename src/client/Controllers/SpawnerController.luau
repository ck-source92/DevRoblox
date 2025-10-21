-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- SpawnerController
local SpawnerController = Knit.CreateController({
	Name = "SpawnerController",
})

return SpawnerController
