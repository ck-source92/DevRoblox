local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SpawnerService = Knit.CreateService({
	Name = "SpawnerService",
	Client = {},
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spawnable = require(ReplicatedStorage.Shared.Classes.Spawnable)

function SpawnerService:SpawnObject(templateName, position)
	local obj = Spawnable.new(templateName, position)
	obj:Spawn()
	return obj
end

-- allow clients to request spawn
function SpawnerService.Client:SpawnObject(player, templateName, position)
	self.Server:SpawnObject(templateName, position)
end

return SpawnerService
