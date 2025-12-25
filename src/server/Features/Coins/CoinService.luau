--!strict
-- Features/Coins/CoinService.luau
-- Handles Coin spawning and collection.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local CoinDomain = require(ReplicatedStorage.Shared.Features.Points.Domain.Coin)

local Assets = ReplicatedStorage:WaitForChild("Assets")

local CoinService = Knit.CreateService({
	Name = "CoinService",
	Client = {},
})

function CoinService:KnitStart()
	task.wait(0.2)
	-- Spawn some initial coins
	for _ = 1, 10 do
		local pos = Vector3.new(math.random(-50, 50), 2, math.random(-50, 50))
		self:SpawnCoin(pos, 10)
	end
end

function CoinService:SpawnCoin(position: Vector3, value: number)
	local coinData = CoinDomain.new(value, "Gold")

	-- Infrastructure Logic: Creating the 3D representation
	local template = Assets:WaitForChild("PartCoin") -- Assuming asset name
	if not template then
		warn("[CoinService] PartCoin asset not found")
		return
	end

	local instance = template:Clone()
	instance.Position = position
	instance.Parent = Workspace

	-- Bind interaction
	instance.Touched:Connect(function(hit)
		if instance.Parent == nil then
			return
		end -- Already collected

		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			self:_collectCoin(player, instance, coinData)
		end
	end)
end

function CoinService:_collectCoin(player: Player, instance: Instance, coinData: any)
	local PointsService = Knit.GetService("PointsService")

	-- Business Logic: Award Points
	PointsService:AddPoints(player, coinData.Value)

	-- Cleanup
	instance:Destroy()
end

return CoinService
