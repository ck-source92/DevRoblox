-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SpawnerService
local SpawnerService = Knit.CreateService({
	Name = "SpawnerService",
	Client = {
		CoinCollected = Knit.CreateSignal(),
	},
})

-- Packages
local Spawnable = require(ReplicatedStorage.Shared.Classes.Spawnable)

-- Knit Lifecycle
function SpawnerService:KnitStart()
	print("SpawnerService Start Run")
	task.wait(3)
	for i = 1, 10 do
		local pos = Vector3.new(math.random(-50, 50), 2, math.random(-50, 50))
		self:SpawnObject("PartCoin", pos)
	end
	print("SpawnerService Start End")
end

-- Functions
function SpawnerService:SpawnObject(templateName: string, position: Vector3)
	local obj = Spawnable.new(templateName, position)
	obj:Spawn()

	-- Destroy object when touches
	obj.Instance.Touched:Connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			self.Client.CoinCollected:Fire(player, 10)
			obj:Destroy()
		end
	end)
end

function SpawnerService.Client:SpawnObject(templateName: string, position: Vector3)
	self.Server:SpawnObject(templateName, position)
end

return SpawnerService
