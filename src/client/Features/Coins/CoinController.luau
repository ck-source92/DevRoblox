--!strict
-- Features/Coins/CoinController.luau
-- Client-side Coin logic (Visuals, effects).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CoinController = Knit.CreateController({
	Name = "CoinController",
})

function CoinController:KnitStart()
	-- Future: Listen for coin spawn events to play sounds/particles locally
	print("[CoinController] Started")
end

return CoinController
