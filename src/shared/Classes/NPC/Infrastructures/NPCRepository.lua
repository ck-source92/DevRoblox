local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local NPCRepository = {}
NPCRepository.__index = NPCRepository

function NPCRepository.new()
	local self = setmetatable({}, NPCRepository)

	self.NPCs = {} :: { [string]: any } -- [npcId] = NPCEntity
	self.OutfitTemplate = nil
	self.GearTemplate = nil

	return self
end

function NPCRepository:Init()
	local DataCacheService = Knit.GetService("DataCacheService")
	self.OutfitTemplate = DataCacheService:GetFile("Template").Outfits
	self.GearTemplate = DataCacheService:GetFile("Template").Gears

	print("[NPCRepository] Initialized with", self:GetOutfitCount(), "outfits")
end

-- Create a new NPC
function NPCRepository:Create(npcEntity): boolean
	if self.NPCs[npcEntity.Id] then
		warn("[NPCRepository] NPC already exists:", npcEntity.Id)
		return false
	end

	self.NPCs[npcEntity.Id] = npcEntity
	return true
end

-- Get NPC by ID
function NPCRepository:Get(npcId: string)
	return self.NPCs[npcId]
end

-- Get all NPCs
function NPCRepository:GetAll(): { any }
	local allNPCs = {}
	for _, npc in pairs(self.NPCs) do
		table.insert(allNPCs, npc)
	end
	return allNPCs
end

-- Get alive NPCs only
function NPCRepository:GetAliveNPCs(): { any }
	local aliveNPCs = {}
	for _, npc in pairs(self.NPCs) do
		if npc.IsAlive then
			table.insert(aliveNPCs, npc)
		end
	end
	return aliveNPCs
end

-- Update NPC
function NPCRepository:Update(npcId: string, updates: any): boolean
	local npc = self.NPCs[npcId]
	if not npc then
		warn("[NPCUsecase] NPC is Despawned - NPC Cannot interact again - NPC not found:" .. npcId)
		return false
	end

	for key, value in pairs(updates) do
		npc[key] = value
	end

	return true
end

-- Delete NPC
function NPCRepository:Delete(npcId: string): boolean
	if not self.NPCs[npcId] then
		warn("[NPCRepository] Cannot delete - NPC not found:", npcId)
		return false
	end

	self.NPCs[npcId] = nil
	return true
end

-- Get outfit data by ID
function NPCRepository:GetOutfitData(outfitId: number): table?
	if not self.OutfitTemplate then
		warn("[NPCRepository] Outfit template not loaded")
		return nil
	end

	return self.OutfitTemplate[outfitId]
end

-- Get random outfit ID
function NPCRepository:GetRandomOutfitId(): number
	if not self.OutfitTemplate then
		warn("[NPCRepository] Outfit template not loaded")
		return 1
	end

	local outfitIds = {}
	for id, _ in pairs(self.OutfitTemplate) do
		table.insert(outfitIds, id)
	end

	return outfitIds[math.random(1, #outfitIds)]
end

-- Get gear data by ID
function NPCRepository:GetGearData(gearId: number): table?
	if not self.GearTemplate then
		warn("[NPCRepository] Gear template not loaded")
		return nil
	end
	return self.GearTemplate[gearId]
end

-- Get random gear ID
function NPCRepository:GetRandomGearId(): number
	if not self.GearTemplate then
		warn("[NPCRepository] Gear template not loaded")
		return 1
	end

	local gearIds = {}
	print("[NPCRepository] Gear template loaded with", #self.GearTemplate, "gears")
	for id, _ in pairs(self.GearTemplate) do
		table.insert(gearIds, id)
	end

	return gearIds[math.random(1, #gearIds)]
end

-- Get outfit count
function NPCRepository:GetOutfitCount(): number
	if not self.OutfitTemplate then
		return 0
	end

	local count = 0
	for _, _ in pairs(self.OutfitTemplate) do
		count = count + 1
	end
	return count
end

-- Get NPC count
function NPCRepository:GetNPCCount(): number
	local count = 0
	for _, _ in pairs(self.NPCs) do
		count = count + 1
	end
	return count
end

return NPCRepository
