local RS = game:GetService("ReplicatedStorage")
local Knit = require(RS.Packages.Knit)
local NPCEntity = require(RS.Shared.Classes.Soccer.NPCEntity)
local NPCSpawner = require(RS.Shared.Classes.Soccer.Infrastucture.NPCSpawner)
local FormationFactory = require(RS.Shared.Classes.Soccer.Services.FormationFactory)

local NPCServiceV2 = Knit.CreateService({ Name = "NPCServiceV2" })

local sessionNPCs = {}

function NPCServiceV2:SpawnForSession(userId, slots)
	sessionNPCs[userId] = {}

	local folder = Instance.new("Folder")
	folder.Name = "NPCs_" .. userId
	folder.Parent = workspace

	for i, slot in ipairs(slots) do
		local id = userId .. "_NPC_" .. i
		local skill = math.random(20, 80)
		local speed = math.random(12, 18)
		local entity = NPCEntity.new(id, skill, speed, slot)
		local model = NPCSpawner.Spawn(id, slot.offset, speed, folder)

		sessionNPCs[userId][id] = { entity = entity, model = model }
	end
end

function NPCServiceV2:ClearSession(userId)
	if not sessionNPCs[userId] then
		return
	end

	for id, data in pairs(sessionNPCs[userId]) do
		NPCSpawner.Destroy(data.model)
	end

	local folder = workspace:FindFirstChild("NPCs_" .. userId)
	if folder then
		folder:Destroy()
	end

	sessionNPCs[userId] = nil
end

function NPCServiceV2:TickSession(userId, playerPosition)
	if not sessionNPCs[userId] then
		return
	end

	for id, data in pairs(sessionNPCs[userId]) do
		local entity = data.entity
		local model = data.model
		if not entity.isActive then
			continue
		end

		local npcPos = model.HumanoidRootPart.Position

		if playerPosition.Z > npcPos.Z + 5 then
			entity:Despawn()
			NPCSpawner.Destroy(data.model)
			sessionNPCs[userId][id] = nil
			continue
		end

		if entity:CanDetectTarget(npcPos, playerPosition) then
			entity:StartChasing()
			NPCSpawner.MoveToward(model, playerPosition, entity.stats.speed)
		end
	end
end

return NPCServiceV2
