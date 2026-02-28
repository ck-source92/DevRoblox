local NPCEntity = require(script.Parent.Parent.Domain.NPCEntity)
local Config = require(script.Parent.Parent.Config)

local NPCUsecase = {}
NPCUsecase.__index = NPCUsecase

function NPCUsecase.new(npcRepository)
	local self = setmetatable({}, NPCUsecase)

	self.repository = npcRepository

	return self
end

-- Spawn a new NPC
function NPCUsecase:SpawnNPC(spawnPosition: Vector3, outfitId: number?, gearId: number?): any
	local selectedOutfitId = outfitId or self.repository:GetRandomOutfitId()
	local selectedGearId = gearId or self.repository:GetRandomGearId()

	-- Validate outfit exists
	local outfitData = self.repository:GetOutfitData(selectedOutfitId)
	if not outfitData then
		warn("[NPCUsecase] Invalid outfit ID:", selectedOutfitId)
		return nil
	end

	local gearData = self.repository:GetGearData(selectedGearId)
	if not gearData then
		warn("[NPCUsecase] Invalid gear ID:", selectedGearId)
		return nil
	end

	-- Create NPC entity with outfit's NPC name
	local npcEntity = NPCEntity.new({
		Username = outfitData.NPCName,
		OutfitId = selectedOutfitId,
		GearId = selectedGearId,
		SpawnPosition = spawnPosition,
	})

	npcEntity:SetOutfitName(outfitData.Name)
	npcEntity:SetGearName(gearData.Name)

	-- Save to repository
	local success = self.repository:Create(npcEntity)

	if not success then
		warn("[NPCUsecase] Failed to create NPC in repository")
		return nil
	end

	print(
		"[NPCUsecase] Spawned NPC:",
		npcEntity.Username,
		"| Outfit:",
		outfitData.DisplayName,
		"| Gear:",
		gearData.DisplayName,
		"| ID:",
		npcEntity.Id
	)

	return npcEntity
end

-- Get random destination within radius
function NPCUsecase:GetRandomDestination(currentPosition: Vector3, radius: number?): Vector3
	local wanderRadius = radius or Config.WANDER_RADIUS

	local randomAngle = math.random() * math.pi * 2
	local randomDistance = math.random() * wanderRadius

	local offsetX = math.cos(randomAngle) * randomDistance
	local offsetZ = math.sin(randomAngle) * randomDistance

	return Vector3.new(currentPosition.X + offsetX, currentPosition.Y, currentPosition.Z + offsetZ)
end

-- Apply damage to NPC
function NPCUsecase:DamageNPC(npcId: string, damage: number): boolean
	local npc = self.repository:Get(npcId)
	if not npc then
		warn("[NPCUsecase] Cannot damage - NPC not found:", npcId)
		return false
	end

	local died = npc:TakeDamage(damage)

	-- Update repository
	self.repository:Update(npcId, npc)

	if died then
		print("[NPCUsecase] NPC died:", npc.Username, "| ID:", npcId)
	end

	return died
end

-- Remove/Delete NPC
function NPCUsecase:RemoveNPC(npcId: string): boolean
	local npc = self.repository:Get(npcId)
	if not npc then
		warn("[NPCUsecase] Cannot remove - NPC not found:", npcId)
		return false
	end

	local success = self.repository:Delete(npcId)
	if success then
		print("[NPCUsecase] Removed NPC:", npc.Username, "| ID:", npcId)
	end

	return success
end

-- Get NPC by ID
function NPCUsecase:GetNPC(npcId: string)
	return self.repository:Get(npcId)
end

-- Get all NPCs
function NPCUsecase:GetAllNPCs()
	return self.repository:GetAll()
end

-- Get alive NPCs
function NPCUsecase:GetAliveNPCs()
	return self.repository:GetAliveNPCs()
end

-- Get Random Outfit NPC
function NPCUsecase:GetRandomOutfitData()
	local OutfitId = self.repository:GetRandomOutfitId()
	local outfitData = self.repository:GetOutfitData(OutfitId)
	return outfitData
end

-- Start interaction with player
function NPCUsecase:StartInteraction(npcId: string, player: Player): boolean
	local npc = self.repository:Get(npcId)
	if not npc then
		warn("[NPCUsecase] Cannot interact - NPC not found:", npcId)
		return false
	end

	if not npc:CanBeInteracted() then
		return false
	end

	npc:StartInteraction(player)
	self.repository:Update(npcId, npc)

	print("[NPCUsecase] Started interaction:", npc.Username, "with", player.Name)
	return true
end

-- End interaction
function NPCUsecase:EndInteraction(npcId: string): boolean
	local npc = self.repository:Get(npcId)
	if not npc then
		return false
	end

	npc:EndInteraction()
	self.repository:Update(npcId, npc)

	return true
end

return NPCUsecase
