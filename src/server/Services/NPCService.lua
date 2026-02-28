local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

-- NPC System
local Config = require(ReplicatedStorage.Shared.Classes.NPC.Config)
local NPCRepository = require(ReplicatedStorage.Shared.Classes.NPC.Infrastructures.NPCRepository)
local NPCUsecase = require(ReplicatedStorage.Shared.Classes.NPC.Applications.NPCUsecase)
local RbxNPCService = require(ReplicatedStorage.Shared.Classes.NPC.RbxNPCService)

-- Interactable System
local InteractableRepository = require(ReplicatedStorage.Shared.Classes.NPC.Infrastructures.InteractableRepository)
local InteractableUsecase = require(ReplicatedStorage.Shared.Classes.NPC.Applications.InteractableUsecase)

-- Dev/Testing
local RbxMockTest = require(ReplicatedStorage.Shared.Classes.NPC.RbxMockTest)

local NPCService = Knit.CreateService({
	Name = "NPCService",
	Client = {},
})

function NPCService:KnitInit()
	self.npcRepository = NPCRepository.new()
	self.npcUsecase = NPCUsecase.new(self.npcRepository)
	self.rbxNpcService = RbxNPCService.new(self.npcUsecase)

	if Config.DEBUG then
		-- Debug/Test tools
		self.mockTest = RbxMockTest.new(self)
	end

	self.rbxNpcService:EnsurePooling()

	self.interactableRepository = InteractableRepository.new()
	self.interactableUsecase = InteractableUsecase.new(self.interactableRepository)

	self:SetCollisionGroup()
	print("[NPCService] Initialized")
end

function NPCService:KnitStart()
	self.npcRepository:Init()
	print("[NPCService] Started")

	if Config.DEBUG then
		local centerPos = workspace:FindFirstChild("Test"):FindFirstChild("CenterPart")
		if centerPos:IsA("BasePart") then
			self.mockTest:CreateMockInteractables(centerPos.Position)
		end

		self.interactableRepository:DiscoverTestInteractables()
		self.mockTest:TestSpawn(centerPos)
	end
end

function NPCService:SetCollisionGroup()
	local success = pcall(function()
		PhysicsService:RegisterCollisionGroup(Config.ISNPC)
	end)

	if not success then
		warn("[NPCService] Collision group already registered (this is fine)")
	end
	PhysicsService:CollisionGroupSetCollidable(Config.ISNPC, Config.ISNPC, false)
	-- NPCs can still collide with the map/terrain
	PhysicsService:CollisionGroupSetCollidable(Config.ISNPC, "Humanoid", false)
end

--#region Spawning/Despawning
function NPCService:SpawnNPC(
	position: Vector3,
	outfitId: number?,
	gearId: number?,
	isInnocent: boolean?,
	variant: string?
): string?
	local npcEntity = self.npcUsecase:SpawnNPC(position, outfitId, gearId)
	if not npcEntity then
		return nil
	end

	local npcModel = self.rbxNpcService:CreateNPCModel(npcEntity, variant, isInnocent)

	if not npcModel then
		warn("[NPCService] Failed to create model for NPC:", npcEntity.Id)
		self.npcUsecase:RemoveNPC(npcEntity.Id)
		return nil
	end

	npcEntity.Model = npcModel
	npcEntity.Humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	npcEntity.HumanoidRootPart = npcModel:FindFirstChild("HumanoidRootPart")

	--[[ Defer network owner assignment to next task cycle to ensure physics stability
	task.defer(function()
		if npcEntity.HumanoidRootPart and npcEntity.HumanoidRootPart.Parent then
			npcEntity.HumanoidRootPart:SetNetworkOwner(nil)
		end
	end)
	]]

	self.rbxNpcService:SetupHealthSystem(npcModel, npcEntity.Id)
	self.npcRepository:Update(npcEntity.Id, npcEntity)

	if Config.DEBUG then
		print("[NPCService] Successfully spawned NPC:", npcEntity.Username, "at", position)
	end

	return npcEntity.Id
end

function NPCService:SpawnTutorialNPCs(spawnZone: { BasePart }): number
	if not spawnZone or #spawnZone < 2 then
		warn("[NPCService] Need at least 2 spawn points for tutorial NPCs")
		return 0
	end

	local spawned = 0

	-- Shuffle spawners
	local shuffledSpawners = {}
	for i, v in ipairs(spawnZone) do
		shuffledSpawners[i] = v
	end

	for i = #shuffledSpawners, 2, -1 do
		local j = math.random(i)
		shuffledSpawners[i], shuffledSpawners[j] = shuffledSpawners[j], shuffledSpawners[i]
	end

	-- Spawn NPC 1: Innocent (Not the target)
	local spawner1 = shuffledSpawners[1]
	if spawner1 and spawner1:IsA("BasePart") then
		local spawnPos1 = self.rbxNpcService:GetRandomPositionInZone(spawner1)
		local npcId1 = self:SpawnNPC(spawnPos1, nil, nil, true)
		print("[NPCService] Spawned NPC", npcId1)
		if npcId1 then
			spawned = spawned + 1
			self:StartNPCWandering(npcId1)
			print("[NPCService] Spawned Tutorial NPC 1 (Innocent)")
		end
		task.wait(0.5)
	end

	-- Spawn NPC 2: True Target
	local spawner2 = shuffledSpawners[2]
	if spawner2 and spawner2:IsA("BasePart") then
		local spawnPos2 = self.rbxNpcService:GetRandomPositionInZone(spawner2)
		local npcId2 = self:SpawnNPC(spawnPos2, nil, nil, false)
		print("[NPCService] Spawned NPC", npcId2)
		if npcId2 then
			spawned = spawned + 1
			self:StartNPCWandering(npcId2)
			print("[NPCService] Spawned Tutorial NPC 2 (True Target)")
		end
	end

	print("[NPCService] Spawned", spawned, "/ 2 Tutorial NPCs")
	return spawned
end

function NPCService:SpawnNPCBatch(
	count: number,
	spawnZone: table,
	outfitId: number?,
	gearId: number?,
	variant: string?
): number
	local spawned = 0

	local shuffledSpawners = {}
	for i, v in ipairs(spawnZone) do
		shuffledSpawners[i] = v
	end

	for i = #shuffledSpawners, 2, -1 do
		local j = math.random(i)
		shuffledSpawners[i], shuffledSpawners[j] = shuffledSpawners[j], shuffledSpawners[i]
	end

	for i = 1, count do
		local spawnerIndex = ((i - 1) % #shuffledSpawners) + 1
		local spawnerPart = shuffledSpawners[spawnerIndex]

		if not spawnerPart or not spawnerPart:IsA("BasePart") then
			warn("[NPCService] Invalid spawner at index", spawnerIndex)
			continue
		end

		local spawnPosition = self.rbxNpcService:GetRandomPositionInZone(spawnerPart)

		if outfitId == 0 then
			outfitId = nil
		end

		if gearId == 0 then
			gearId = nil
		end

		local npcId = self:SpawnNPC(spawnPosition, outfitId or nil, gearId or nil, nil, variant)
		print("[NPCService] Spawned NPC", npcId)
		if npcId then
			spawned = spawned + 1
			self:StartNPCWandering(npcId)
		end

		task.wait(Config.SPAWN_BATCH_DELAY)
	end

	print("[NPCService] Spawned", spawned, "/", count, "NPCs")
	return spawned
end

function NPCService:DespawnNPC(npcId: string): boolean
	local npc = self.npcUsecase:GetNPC(npcId)
	if not npc then
		return false
	end

	if npc.Model then
		self.npcUsecase:RemoveNPC(npcId)
		self.rbxNpcService:DestroyNPCModel(npcId, npc.Model)
	end

	return true
end

function NPCService:DespawnAllNPCs()
	local allNPCs = self.npcUsecase:GetAllNPCs()

	for _, npc in ipairs(allNPCs) do
		self:DespawnNPC(npc.Id)
	end

	print("[NPCService] Despawned all NPCs")
end

function NPCService:GetNPCCount(): number
	return self.npcRepository:GetNPCCount()
end
-- #endregion

--#region NPC Behavior System
function NPCService:StartNPCWandering(npcId: string)
	task.spawn(function()
		while true do
			local npc = self.npcUsecase:GetNPC(npcId)

			-- Check if NPC was despawned or model destroyed
			if not npc or not npc.IsAlive or not npc.Model or not npc.Model.Parent then
				break
			end

			if npc:CanTransitionState() then
				self:ProcessNPCStateTransition(npcId, npc)
			end

			task.wait(1)
		end
	end)
end

function NPCService:ProcessNPCStateTransition(npcId: string, npc: any)
	local chanceWalking = 0.25
	local chanceObject = 0.65
	-- local chanceInteraction = 0.10
	local chanceRunning = 0.10

	local random = math.random()

	if random < chanceWalking then
		self:HandleWalkingState(npcId, npc) -- 25% -- wandering
	elseif random < (chanceObject + chanceWalking) then
		self:HandleObjectInteractionState(npcId, npc) -- 65% -- interaction with object/doing task
	elseif random < (chanceRunning + chanceObject + chanceWalking) then
		self:HandleRunningState(npcId, npc) -- 10% -- running
	else
		self:HandleIdleState(npcId, npc) -- 5% -- idle state
	end
end

-- #endregion

--#region State Handlers
function NPCService:HandleWalkingState(npcId: string, npc: any)
	npc:SetBusy(true)
	npc:SetState(Config.States.WALKING)

	local targetPos = self.rbxNpcService:GetRandomWanderPosition(npc.SpawnPosition)
	npc.TargetPosition = targetPos
	self.npcRepository:Update(npcId, npc)

	if Config.DEBUG then
		print("[NPCService] NPC", npcId, "walking to ", targetPos)
	end

	self.rbxNpcService:MoveNPCToPosition(npc.Model, targetPos, true)

	npc:SetBusy(false)
	self.npcRepository:Update(npcId, npc)
end

function NPCService:HandleRunningState(npcId: string, npc: any)
	npc:SetBusy(true)
	npc:SetState(Config.States.RUNNING)

	local targetPos = self.rbxNpcService:GetRandomWanderPosition(npc.SpawnPosition)
	npc.TargetPosition = targetPos
	self.npcRepository:Update(npcId, npc)

	if Config.DEBUG then
		print("[NPCService] NPC", npcId, "running to ", targetPos)
	end

	self.rbxNpcService:MoveNPCToPosition(npc.Model, targetPos, false)

	npc:SetBusy(false)
	self.npcRepository:Update(npcId, npc)
end

function NPCService:HandleInteractionState(npcId: string, npc: any)
	if not npc:CanInteractWithNPC() then
		self:HandleObservingState(npcId, npc, "interaction on cooldown")
		return
	end

	local allNPCs = self.npcUsecase:GetAllNPCs()
	local partner = self.rbxNpcService:FindNearbyNPC(npc.Model, allNPCs)

	if not partner then
		self:HandleObservingState(npcId, npc, "no interaction partner")
		return
	end

	self:PerformNPCInteraction(npcId, npc, partner)
end

function NPCService:PerformNPCInteraction(npcId: string, npc: any, partner: any)
	local duration = math.random(Config.NPC_INTERACTION_DURATION_MIN, Config.NPC_INTERACTION_DURATION_MAX)

	npc:StartNPCInteraction(partner.Id, duration)
	partner:StartNPCInteraction(npc.Id, duration)

	self.npcRepository:Update(npcId, npc)
	self.npcRepository:Update(partner.Id, partner)

	self.rbxNpcService:MakeNPCsInteract(npc.Model, partner.Model)

	if Config.DEBUG then
		print("[NPCService] NPC", npc.Username, "interacting with", partner.Username, "for", duration, "seconds")
	end

	task.wait(duration)

	npc:EndNPCInteraction()
	partner:EndNPCInteraction()

	self.npcRepository:Update(npcId, npc)
	self.npcRepository:Update(partner.Id, partner)

	if Config.DEBUG then
		print("[NPCService] Interaction ended between", npc.Username, "and", partner.Username)
	end
end

function NPCService:HandleObjectInteractionState(npcId: string, npc: any)
	npc:SetBusy(true)

	-- Get correct repository based on mode
	local interactableUsecase = Config.DEBUG and self.interactableUsecase

	if not interactableUsecase then
		warn("[NPCService] InteractableUsecase not available")
		self:HandleObservingState(npcId, npc, "no interactable system")
		npc:SetBusy(false)
		return
	end

	local map = Config.DEBUG and "Test"
	local interactable = interactableUsecase:GetRandomInteractable(map)

	if not interactable then
		self:HandleObservingState(npcId, npc, "no interactable found")
		npc:SetBusy(false)
		return
	end

	if Config.DEBUG then
		print("[NPCService] NPC", npc.Id, "moving to interact with", interactable.InteractType)
	end

	if npc:GetState() == Config.States.WALKING then
		npc:SetState(Config.States.WALKING)
		self.npcRepository:Update(npcId, npc)
	else
		npc:SetState(Config.States.RUNNING)
		self.npcRepository:Update(npcId, npc)
	end

	-- Get safe position around object (not on top of it)
	local targetPosition = interactableUsecase:GetInteractionPosition(interactable)
	local success = self.rbxNpcService:MoveNPCToPosition(npc.Model, targetPosition, true)

	if not success then
		self:HandleObservingState(npcId, npc, "failed to reach object")
		npc:SetBusy(false)
		return
	end

	interactableUsecase:StartInteraction(npc, interactable)
	self.npcRepository:Update(npcId, npc)

	-- Face NPC towards the object (not the interaction position)
	self.rbxNpcService:FaceToTarget(npc.Model, interactable.Position)

	-- Only wield gear for interactions that require tools
	local requiresGear = interactableUsecase:RequiresGear(interactable)

	if requiresGear and npc.Model then
		self.rbxNpcService:WieldGear(npc.Model)
	end

	local animSuccess = self.rbxNpcService:PlayInteractionAnimation(npcId, interactable.InteractType)
	if not animSuccess then
		warn("[NPCService] Failed to play interaction animation for", interactable.InteractType)
	end

	local duration = math.random(5, 6)
	task.wait(duration)

	self.rbxNpcService:StopInteractionAnimation(npcId, interactable.InteractType)

	-- Holster gear back after interaction ends (only if we wielded it)
	if requiresGear and npc.Model then
		self.rbxNpcService:HolsterGear(npc.Model)
	end

	interactableUsecase:EndInteraction(npc, interactable)
	self.npcRepository:Update(npcId, npc)

	npc:SetBusy(false)

	if Config.DEBUG then
		print("[NPCService] NPC", npc.Username, "finished interacting with", interactable.InteractType)
	end
end

function NPCService:HandleObservingState(npcId: string, npc: any, reason: string?)
	npc:SetState(Config.States.OBSERVING)
	self.npcRepository:Update(npcId, npc)

	if Config.DEBUG then
		local message = "[NPCService] NPC " .. npc.Username .. " observing"
		if reason then
			message = message .. " (" .. reason .. ")"
		end
		print(message)
	end
end

function NPCService:HandleIdleState(npcId: string, npc: any)
	npc:SetState(Config.States.IDLE)
	self.npcRepository:Update(npcId, npc)

	if Config.DEBUG then
		print("[NPCService] NPC", npc.Username, "idling")
	end
end
-- #endregion

return NPCService
