-- Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

-- Services
local CoinService = nil

-- CoinController
local CoinController = Knit.CreateController({
	Name = "CoinController",
})

function CoinController:KnitStart()
	CoinService = Knit.GetService("CoinService")
	print("[Coin Service] Service : ", CoinService)

	-- for _ = 1, 10 do
	-- 	local pos = Vector3.new(math.random(-50, 50), 5, math.random(-50, 50))
	-- 	CoinService:SpawnObject("PartCoin", pos)
	-- end
end

return CoinController
