-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- CoinController
local CoinController = Knit.CreateController({
	Name = "CoinController",
})

return CoinController
