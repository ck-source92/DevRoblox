-- Packages
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Services
local DataService = nil

-- Data Classes
local Coin = require(ReplicatedStorage.Shared.Classes.Coin)

-- Create Service
local CoinService = Knit.CreateService({
	Name = "CoinService",
	Client = {},
})

-- -- Knit Lifecycle
-- function CoinService:KnitStart()
-- 	task.wait(0.2)
-- 	for _ = 1, 10 do
-- 		local pos = Vector3.new(math.random(-50, 50), 2, math.random(-50, 50))
-- 		self:SpawnObject("PartCoin", pos)
-- 	end
-- end

-- Functions
function CoinService:SpawnObject(templateName: string, position: Vector3)
	local obj = Coin.new(templateName, position)
	obj:Spawn()

	-- Touched
	obj.Instance.Touched:Connect(function(hit)
		local Player = game.Players:GetPlayerFromCharacter(hit.Parent)
		-- local PointService = Knit.GetService("PointService")

		if Player then
			-- PointService:AddPoint(Player, 10) -- Add Point to Player
			obj:Destroy()
		end
	end)
end

return CoinService
