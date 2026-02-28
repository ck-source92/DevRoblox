--[[
	RbxNPCService.lua
	Handles Roblox-specific NPC model creation, animation, pathfinding, and gear management.
	
	Responsibilities:
	- Object pooling for NPC models
	- NPC model creation with outfit variants
	- Animation playback (idle, walk, run, interactions)
	- Gear attachment/wielding/holstering
	- Pathfinding and movement
	- Health system integration
	- NPC-to-NPC interactions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local AnimationModule = require(ReplicatedStorage.Shared.Classes.NPC.AnimationModule)
local ObjectPool = require(ReplicatedStorage.Shared.Classes.ObjectPool)

-- Constants
local POOL_PREWARM_COUNT = 10
local SPAWN_OFFSET_RANGE = 3
local DEFAULT_VARIANTS = { "Variant1", "Variant2", "Variant3" }
local PATHFINDING_CONFIG = {
	AgentRadius = 2,
	AgentHeight = 7,
	AgentCanJump = false,
	WaypointSpacing = 10,
}

local RbxNPCService = {}
RbxNPCService.__index = RbxNPCService

--#region Private Utility Functions

--- Sets the collision group for all BaseParts in a model
local function setColliderGroup(npc: Model, groupName: string)
	if not npc or not npc:IsA("Model") then
		return
	end

	for _, part in ipairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

--- Gets or creates the NPCs folder in workspace
local function getNPCFolder(): Folder
	local npcFolder = Workspace:FindFirstChild("NPCs")
	if npcFolder then
		return npcFolder
	end

	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = Workspace

	return npcFolder
end

--- Calculates the CFrame offset between two parts
local function getOffset(bodyPart: BasePart, targetPart: BasePart): CFrame
	return bodyPart.CFrame:ToObjectSpace(targetPart.CFrame)
end

--- Fisher-Yates shuffle for random array ordering
local function shuffleArray<T>(array: { T }): { T }
	local shuffled = table.clone(array)
	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

--#endregion

--#region Constructor

function RbxNPCService.new(npcUsecase)
	local self = setmetatable({}, RbxNPCService)

	self.usecase = npcUsecase
	self.NPCFolder = getNPCFolder()

	-- Storage for NPC connections and animations
	self.connections = {}
	self.animationModules = {}

	self.pool = {}

	return self
end

--#endregion

--#region Object Pooling

--- Creates a basic NPC template for pooling
function RbxNPCService:CreateNPCTemplate(): Model
	local template = self:CreateBasicRig()
	template.Name = "[Template]NPC"
	template.Parent = nil

	if Config.DEBUG then
		print("[RbxNPCService] Created basic NPC template")
	end

	return template
end

--- Ensures the object pool is initialized
function RbxNPCService:EnsurePooling()
	if self.pool and self.pool.Get then
		return
	end

	self.pool = ObjectPool.new({
		create = function()
			return self:CreateNPCTemplate()
		end,
		prewarmCount = POOL_PREWARM_COUNT,
		defaultParent = nil,
		onTake = function()
			if Config.DEBUG then
				print("[RbxNPCService] NPC taken from pool")
			end
		end,
		onRelease = function(obj)
			self:_ResetPooledNPC(obj)
		end,
	})

	if Config.DEBUG then
		print("[RbxNPCService] Object pool initialized with", POOL_PREWARM_COUNT, "pre-warmed NPCs")
	end
end

--- Resets a pooled NPC to default state
function RbxNPCService:_ResetPooledNPC(npcModel: Model)
	self:RemoveGear(npcModel)

	npcModel.Name = "[Template]NPC"
	npcModel.Parent = nil

	-- Clear all attributes
	for attrName in pairs(npcModel:GetAttributes()) do
		npcModel:SetAttribute(attrName, nil)
	end

	-- Reset humanoid properties
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 100
		humanoid.MaxHealth = 100
		humanoid.WalkSpeed = 16
		humanoid.DisplayName = ""
	end

	if Config.DEBUG then
		print("[RbxNPCService] NPC released to pool")
	end
end

--#endregion

--#region NPC Model Creation
--- Creates and configures an NPC model from the pool
function RbxNPCService:CreateNPCModel(npcEntity, variant: string?, isInnocent: boolean?): Model?
	-- Get model from pool
	local npcModel = self.pool:Get()
	if not npcModel then
		warn("[RbxNPCService] Failed to get NPC from pool")
		return nil
	end

	-- Set role attribute
	if isInnocent then
		npcModel:SetAttribute("Role", "Spy")
	end

	-- Apply outfit
	local outfitModel = self:FindOutfitModel(npcEntity.OutfitName, variant)
	if not outfitModel then
		warn("[RbxNPCService] Outfit not found:", npcEntity.OutfitName)
		return nil
	end

	npcModel:ClearAllChildren()
	for _, child in ipairs(outfitModel:GetChildren()) do
		child:Clone().Parent = npcModel
	end

	-- Verify root part exists
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then
		warn("[RbxNPCService] No HumanoidRootPart found after applying outfit")
		return nil
	end

	-- Apply gear
	if not self:AttachGear(npcModel, npcEntity.GearName) then
		warn("[RbxNPCService] Gear not found:", npcEntity.GearName)
		return nil
	end

	-- Position NPC
	npcModel.Name = npcEntity.Username
	npcModel.PrimaryPart = rootPart

	local spawnOffset = Vector3.new(
		math.random(-SPAWN_OFFSET_RANGE, SPAWN_OFFSET_RANGE),
		0,
		math.random(-SPAWN_OFFSET_RANGE, SPAWN_OFFSET_RANGE)
	)
	npcModel:SetPrimaryPartCFrame(CFrame.new(npcEntity.SpawnPosition + spawnOffset))

	-- Configure humanoid
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = npcEntity.Health
		humanoid.MaxHealth = npcEntity.MaxHealth
		humanoid.WalkSpeed = Config.WALK_SPEED
		humanoid.DisplayName = npcEntity.Username
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		self:SetupAnimations(humanoid, npcEntity.Id)
	end

	-- Finalize setup
	npcModel:SetAttribute("NPCId", npcEntity.Id)
	npcModel.Parent = self.NPCFolder
	setColliderGroup(npcModel, Config.ISNPC)

	if Config.DEBUG then
		print("[RbxNPCService] Created NPC:", npcEntity.Username)
	end

	return npcModel
end

--- Finds an outfit model by name, checking variant folders first
function RbxNPCService:FindOutfitModel(outfitName: string, variant: string?): Model?
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if not assetsFolder then
		warn("[RbxNPCService] Assets folder not found")
		return nil
	end

	local outfitFolder = assetsFolder:FindFirstChild("Outfits")
	if not outfitFolder then
		warn("[RbxNPCService] Outfits folder not found")
		return nil
	end

	local cosmeticsFolder = outfitFolder:FindFirstChild("CosmeticsSystem")
	if not cosmeticsFolder then
		warn("[RbxNPCService] CosmeticsSystem folder not found")
		return nil
	end

	-- Determine target variant
	local targetVariant = variant
	if not targetVariant or targetVariant == "" then
		targetVariant = DEFAULT_VARIANTS[math.random(1, #DEFAULT_VARIANTS)]
	end

	-- Try variant path first: /Assets/CosmeticsSystem/{variant}/{outfitName}
	local variantFolder = cosmeticsFolder:FindFirstChild(targetVariant)
	if variantFolder then
		local model = variantFolder:FindFirstChild(outfitName)
		if model and model:IsA("Model") then
			if Config.DEBUG then
				print("[RbxNPCService] Found outfit model:", outfitName, "in", targetVariant)
			end
			return model
		end
	end

	-- Fallback: Try direct path (for outfits without variants)
	local model = cosmeticsFolder:FindFirstChild(outfitName)
	if model and model:IsA("Model") then
		if Config.DEBUG then
			print("[RbxNPCService] Found outfit model at fallback path:", outfitName)
		end
		return model
	end

	warn("[RbxNPCService] Outfit model not found:", outfitName, "variant:", targetVariant)
	return nil
end

--- Creates a basic humanoid rig (used as pool template)
function RbxNPCService:CreateBasicRig(): Model
	local model = Instance.new("Model")

	-- HumanoidRootPart
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Parent = model

	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "UpperTorso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Parent = model

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	model.PrimaryPart = rootPart

	-- Weld parts together
	local neckWeld = Instance.new("WeldConstraint")
	neckWeld.Part0 = torso
	neckWeld.Part1 = head
	neckWeld.Parent = torso

	local waistWeld = Instance.new("WeldConstraint")
	waistWeld.Part0 = rootPart
	waistWeld.Part1 = torso
	waistWeld.Parent = rootPart

	return model
end

--#endregion

--#region Animation Management

--- Sets up animations for an NPC using AnimationModule
function RbxNPCService:SetupAnimations(humanoid: Humanoid, npcId: string): any?
	local npcModel = humanoid.Parent
	if not npcModel then
		warn("[RbxNPCService] Cannot setup animations - no parent model")
		return nil
	end

	local animModule = AnimationModule.new()
	animModule:LoadCharacter(npcModel)

	self.animationModules[npcId] = animModule

	if animModule:HasAnimation("Idle") then
		animModule:Play("Idle")
	end

	if Config.DEBUG then
		print("[RbxNPCService] Setup animations for:", npcModel.Name)
	end

	return animModule
end

--- Plays an interaction animation, stopping movement animations first
function RbxNPCService:PlayInteractionAnimation(npcId: string, interactType: string): boolean
	local animModule = self.animationModules[npcId]
	if not animModule then
		warn("[RbxNPCService] No AnimationModule found for NPC:", npcId)
		return false
	end

	if not animModule:HasAnimation(interactType) then
		warn("[RbxNPCService] Animation not found:", interactType)
		return false
	end

	-- Stop movement animations before playing interaction
	animModule:Stop("Walk")
	animModule:Stop("Run")
	animModule:Stop("Idle")
	animModule:Play(interactType)

	if Config.DEBUG then
		print("[RbxNPCService] Playing interaction animation:", interactType, "for NPC:", npcId)
	end

	return true
end

--- Stops an interaction animation and returns to idle
function RbxNPCService:StopInteractionAnimation(npcId: string, interactType: string)
	local animModule = self.animationModules[npcId]
	if not animModule then
		return
	end

	animModule:StopPriority(Enum.AnimationPriority.Action)

	if animModule:HasAnimation("Idle") then
		animModule:Play("Idle")
	end

	if Config.DEBUG then
		print("[RbxNPCService] Stopped interaction animation:", interactType, "for NPC:", npcId)
	end
end

--- Stops all movement and interaction animations
function RbxNPCService:_StopAllAnimations(animModule)
	if not animModule then
		return
	end

	animModule:Stop("Idle")
	animModule:Stop("Walk")
	animModule:Stop("Run")
end

--#endregion

--#region Health & Lifecycle Management

--- Sets up health tracking and death handling for an NPC
function RbxNPCService:SetupHealthSystem(npcModel: Model, npcId: string)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not self.connections[npcId] then
		self.connections[npcId] = {}
	end

	-- Health change tracking
	local damageConnection = humanoid.HealthChanged:Connect(function(_health)
		local currentHumanoid = npcModel:FindFirstChildOfClass("Humanoid")
		if not currentHumanoid then
			return
		end

		local currentHealth = currentHumanoid.Health
		local maxHealth = currentHumanoid.MaxHealth
		local damage = maxHealth - currentHealth

		if damage > 0 then
			local npc = self.usecase:GetNPC(npcId)
			if npc then
				npc.Health = currentHealth
			end
		end
	end)

	-- Death handling
	local diedConnection = humanoid.Died:Connect(function()
		print("[RbxNPCService] NPC died:", npcModel.Name)
		self.usecase:DamageNPC(npcId, 9999)
		self:CleanupNPC(npcId, npcModel)
	end)

	table.insert(self.connections[npcId], damageConnection)
	table.insert(self.connections[npcId], diedConnection)
end

--- Adds a name billboard above an NPC's head
function RbxNPCService:AddNameBillboard(npcModel: Model, npcName: string)
	local head = npcModel:FindFirstChild("Head")
	if not head then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = npcName
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = billboard
end

--#endregion

--#region Cleanup

--- Cleans up an NPC, disconnecting events and returning to pool
function RbxNPCService:CleanupNPC(npcId: string, npcModel: Model)
	-- Disconnect all connections
	if self.connections[npcId] then
		for _, connection in ipairs(self.connections[npcId]) do
			connection:Disconnect()
		end
		self.connections[npcId] = nil
	end

	-- Clear animation module reference
	if self.animationModules[npcId] then
		self.animationModules[npcId] = nil
	end

	-- Reset humanoid health and return to pool
	npcModel.Parent = nil
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
	end

	self.pool:Release(npcModel)

	if Config.DEBUG then
		print("[RbxNPCService] Released NPC model to pool:", npcModel.Name)
	end
end

--- Alias for CleanupNPC (for semantic clarity)
function RbxNPCService:DestroyNPCModel(npcId: string, npcModel: Model)
	self:CleanupNPC(npcId, npcModel)
end

--#endregion

--#region Gear System

--- Attaches a random gear to an NPC
function RbxNPCService:AttachRandomGear(npcModel: Model): string?
	local gearName = self:_GetRandomGearName()
	if not gearName then
		if Config.DEBUG then
			warn("[RbxNPCService] No gears found in folder")
		end
		return nil
	end

	return self:AttachGear(npcModel, gearName)
end

--- Attaches a specific gear to an NPC's LowerTorso
function RbxNPCService:AttachGear(npcModel: Model, gearName: string): string?
	local lowerTorso = npcModel:FindFirstChild("LowerTorso")
	if not lowerTorso then
		if Config.DEBUG then
			warn("[RbxNPCService] LowerTorso not found for gear attachment")
		end
		return nil
	end

	local gear = self:_CloneGear(gearName)
	if not gear then
		if Config.DEBUG then
			warn("[RbxNPCService] Failed to clone gear:", gearName)
		end
		return nil
	end

	self:_WeldGearToPart(gear, lowerTorso)

	if Config.DEBUG then
		print("[RbxNPCService] Attached gear:", gearName, "to NPC")
	end

	return gearName
end

--- Removes gear from an NPC
function RbxNPCService:RemoveGear(npcModel: Model)
	local gear = npcModel:FindFirstChild("NPCGear", true)
	if gear then
		gear:Destroy()
		if Config.DEBUG then
			print("[RbxNPCService] Removed gear from NPC")
		end
	end
end

--- Returns a random gear name from the Gears folder
function RbxNPCService:_GetRandomGearName(): string?
	local gearsFolder = ReplicatedStorage.Assets:FindFirstChild("Gears")
	if not gearsFolder then
		return nil
	end

	local generalFolder = gearsFolder:FindFirstChild("General")
	if not generalFolder then
		return nil
	end

	local normalFolder = generalFolder:FindFirstChild("Normal")
	if not normalFolder then
		return nil
	end

	local gears = normalFolder:GetChildren()
	if #gears == 0 then
		return nil
	end

	return gears[math.random(1, #gears)].Name
end

--- Clones a gear by name from the Gears folder (recursive search)
function RbxNPCService:_CloneGear(gearName: string): BasePart?
	local gearsFolder = ReplicatedStorage.Assets:FindFirstChild("Gears")
	if not gearsFolder then
		return nil
	end

	local function findGear(folder): BasePart?
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("BasePart") and child.Name == gearName then
				return child
			elseif child:IsA("Folder") or child:IsA("Model") then
				local found = findGear(child)
				if found then
					return found
				end
			end
		end
		return nil
	end

	local template = findGear(gearsFolder)
	if not template or not template:IsA("BasePart") then
		return nil
	end

	local gear = template:Clone()
	gear.Name = "Gear - " .. template.Name
	gear.CanCollide = false
	gear.CanTouch = false

	return gear
end

--- Welds gear to a body part using RigSample offsets
function RbxNPCService:_WeldGearToPart(gear: BasePart, part: BasePart)
	local rigSample = Workspace:FindFirstChild("AvatarStuff") and Workspace.AvatarStuff:FindFirstChild("RigSample")
	local rigLowerTorso = rigSample and rigSample:FindFirstChild("LowerTorso")
	local rigGear = rigLowerTorso and rigLowerTorso:FindFirstChild("Gear")

	if rigLowerTorso and rigGear then
		local offset = getOffset(rigLowerTorso, rigGear)
		gear.CFrame = part.CFrame * offset
	else
		warn("[RbxNPCService] RigSample missing Gear on LowerTorso, using fallback position")
		gear.CFrame = part.CFrame * CFrame.new(0, 0.2, 0.35) * CFrame.Angles(0, math.rad(180), math.rad(35))
	end

	gear.Parent = part

	local weld = Instance.new("WeldConstraint")
	weld.Name = "GearWeld"
	weld.Part0 = part
	weld.Part1 = gear
	weld.Parent = gear
end

--- Moves gear from LowerTorso to RightHand for interactions
function RbxNPCService:WieldGear(npcModel: Model): boolean
	local rightHand = npcModel:FindFirstChild("RightHand")
	local lowerTorso = npcModel:FindFirstChild("LowerTorso")

	if not rightHand or not lowerTorso then
		warn("[RbxNPCService] WieldGear: NPC missing RightHand or LowerTorso")
		return false
	end

	-- Find gear in LowerTorso
	local gear = self:_FindGearInPart(lowerTorso)
	if not gear then
		warn("[RbxNPCService] WieldGear: Gear not found in LowerTorso")
		return false
	end

	-- Get offset from RigSample
	local rigSample = Workspace.AvatarStuff.RigSample
	local rigRightHand = rigSample:FindFirstChild("RightHand")
	local rigGear = rigRightHand and rigRightHand:FindFirstChild("Gear")

	if not rigGear then
		warn("[RbxNPCService] WieldGear: RigSample RightHand Gear missing")
		return false
	end

	local offset = getOffset(rigRightHand, rigGear)

	-- Remove old weld and move gear
	self:_RemoveGearWeld(gear)
	gear.Parent = rightHand
	gear.CFrame = rightHand.CFrame * offset
	self:_CreateGearWeld(gear, rightHand)

	if Config.DEBUG then
		print("[RbxNPCService] NPC wielding gear in RightHand:", npcModel.Name)
	end

	return true
end

--- Moves gear back from RightHand to LowerTorso after interaction
function RbxNPCService:HolsterGear(npcModel: Model): boolean
	local rightHand = npcModel:FindFirstChild("RightHand")
	local lowerTorso = npcModel:FindFirstChild("LowerTorso")

	if not rightHand or not lowerTorso then
		warn("[RbxNPCService] HolsterGear: NPC missing RightHand or LowerTorso")
		return false
	end

	-- Find gear in RightHand
	local gear = self:_FindGearInPart(rightHand)
	if not gear then
		if Config.DEBUG then
			print("[RbxNPCService] HolsterGear: Gear not in RightHand (might be already holstered)")
		end
		return false
	end

	-- Get offset from RigSample
	local rigSample = Workspace.AvatarStuff.RigSample
	local rigLowerTorso = rigSample:FindFirstChild("LowerTorso")
	local rigGear = rigLowerTorso and rigLowerTorso:FindFirstChild("Gear")

	if not rigGear then
		warn("[RbxNPCService] HolsterGear: RigSample LowerTorso Gear missing")
		return false
	end

	local offset = getOffset(rigLowerTorso, rigGear)

	-- Remove old weld and move gear
	self:_RemoveGearWeld(gear)
	gear.Parent = lowerTorso
	gear.CFrame = lowerTorso.CFrame * offset
	self:_CreateGearWeld(gear, lowerTorso)

	if Config.DEBUG then
		print("[RbxNPCService] NPC holstered gear back to LowerTorso:", npcModel.Name)
	end

	return true
end

--- Finds gear in a body part
function RbxNPCService:_FindGearInPart(part: BasePart): BasePart?
	local gear = part:FindFirstChild("Gear", true) or part:FindFirstChildWhichIsA("BasePart")
	if gear and gear.Name:match("Gear") then
		return gear
	end
	return nil
end

--- Removes the GearWeld from a gear
function RbxNPCService:_RemoveGearWeld(gear: BasePart)
	local oldWeld = gear:FindFirstChild("GearWeld")
	if oldWeld then
		oldWeld:Destroy()
	end
end

--- Creates a new weld between gear and body part
function RbxNPCService:_CreateGearWeld(gear: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "GearWeld"
	weld.Part0 = part
	weld.Part1 = gear
	weld.Parent = gear
end

--#endregion

--#region Movement & Pathfinding

--- Gets a random position within a zone part
function RbxNPCService:GetRandomPositionInZone(zonePart: BasePart): Vector3
	local size = zonePart.Size
	local pos = zonePart.Position

	local randomX = pos.X + (math.random() - 0.5) * size.X
	local randomY = pos.Y + size.Y / 2 + 5
	local randomZ = pos.Z + (math.random() - 0.5) * size.Z

	return Vector3.new(randomX, randomY, randomZ)
end

--- Gets a random wander position around a spawn point
function RbxNPCService:GetRandomWanderPosition(spawnPosition: Vector3, wanderRadius: number?): Vector3
	local radius = wanderRadius or Config.WANDER_RADIUS

	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius

	local offsetX = math.cos(angle) * distance
	local offsetZ = math.sin(angle) * distance

	return Vector3.new(spawnPosition.X + offsetX, spawnPosition.Y, spawnPosition.Z + offsetZ)
end

--- Moves an NPC to a target position using pathfinding
function RbxNPCService:MoveNPCToPosition(
	npcModel: Model,
	targetPosition: Vector3,
	waitingForCompletion: boolean?
): boolean
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local rootPart = npcModel:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart then
		warn("[RbxNPCService] Cannot move NPC - missing Humanoid or HumanoidRootPart")
		return false
	end

	if rootPart.Anchored then
		warn("[RbxNPCService] HumanoidRootPart is anchored - unanchoring")
		rootPart.Anchored = false
	end

	-- Get NPC data and animation module
	local npcId = npcModel:GetAttribute("NPCId")
	local npcEntity = self.usecase:GetNPC(npcId)
	local animModule = npcId and self.animationModules[npcId]

	-- Compute path
	local path = PathfindingService:CreatePath(PATHFINDING_CONFIG)

	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, targetPosition)
	end)

	if not success then
		warn("[RbxNPCService] Path computation failed:", errorMessage)
		return false
	end

	if path.Status == Enum.PathStatus.NoPath then
		if Config.DEBUG then
			warn("[RbxNPCService] No path found for", npcModel.Name)
		end
		return false
	end

	local waypoints = path:GetWaypoints()
	if #waypoints == 0 then
		return false
	end

	-- Debug: Create visible parts at waypoints
	if Config.DEBUG then
		print("[RbxNPCService] Path found with", #waypoints, "waypoints for", npcModel.Name)
		for i, waypoint in ipairs(waypoints) do
			local debugPart = Instance.new("Part")
			debugPart.Name = "Waypoint_" .. i
			debugPart.Shape = Enum.PartType.Ball
			debugPart.Size = Vector3.new(0.6, 0.6, 0.6)
			debugPart.CanCollide = false
			debugPart.CanTouch = false
			debugPart.TopSurface = Enum.SurfaceType.Smooth
			debugPart.BottomSurface = Enum.SurfaceType.Smooth
			debugPart.CFrame = CFrame.new(waypoint.Position)
			debugPart.Anchored = true

			-- Color based on waypoint action
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				debugPart.Color = Color3.fromRGB(255, 255, 0) -- Yellow for jump
			else
				debugPart.Color = Color3.fromRGB(0, 255, 0) -- Green for normal
			end

			debugPart.Parent = Workspace
		end
		print("[RbxNPCService] Created", #waypoints, "waypoint debug parts for", npcModel.Name)
	end

	-- Start movement animation based on NPC state
	self:_StartMovementAnimation(humanoid, animModule, npcEntity, npcId)

	-- Movement state
	local currentWaypointIndex = 1
	local movementComplete = false

	local function moveToNextWaypoint()
		if currentWaypointIndex > #waypoints then
			return
		end

		local waypoint = waypoints[currentWaypointIndex]

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		humanoid:MoveTo(waypoint.Position)
		currentWaypointIndex += 1
	end

	moveToNextWaypoint()

	-- Handle waypoint reaching
	local reachedConnection
	reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
		if reached and currentWaypointIndex <= #waypoints then
			moveToNextWaypoint()
		else
			-- Movement finished - return to idle
			self:_StopMovementAnimation(animModule)
			reachedConnection:Disconnect()
			movementComplete = true
		end
	end)

	-- Wait for completion if requested
	if waitingForCompletion then
		while not movementComplete do
			task.wait(0.1)
		end
	end

	return true
end

--- Starts the appropriate movement animation based on NPC state
function RbxNPCService:_StartMovementAnimation(humanoid: Humanoid, animModule, npcEntity, npcId: string)
	if not animModule then
		return
	end

	local currentState = npcEntity:GetState()

	-- Stop all movement animations first
	self:_StopAllAnimations(animModule)

	-- Play appropriate animation and set speed
	if currentState == Config.States.RUNNING and animModule:HasAnimation("Run") then
		humanoid.WalkSpeed = Config.RUN_SPEED
		animModule:Play("Run")
		if Config.DEBUG then
			print("[RbxNPCService] NPC is running:", npcId)
		end
	elseif animModule:HasAnimation("Walk") then
		humanoid.WalkSpeed = Config.WALK_SPEED
		animModule:Play("Walk")
	end
end

--- Stops movement animations and returns to idle
function RbxNPCService:_StopMovementAnimation(animModule)
	if not animModule then
		return
	end

	animModule:Stop("Walk")
	animModule:Stop("Run")

	if animModule:HasAnimation("Idle") then
		animModule:Play("Idle")
	end
end

--#endregion

--#region NPC Orientation

--- Makes an NPC face a target position
function RbxNPCService:FaceToTarget(npcModel: Model, targetPosition: Vector3): boolean
	local hrp = npcModel:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[RbxNPCService] Cannot find HumanoidRootPart for", npcModel.Name)
		return false
	end

	local npcPosition = hrp.Position
	local lookAtDirection = Vector3.new(targetPosition.X, npcPosition.Y, targetPosition.Z)
	hrp.CFrame = CFrame.new(npcPosition, lookAtDirection)

	return true
end

--#endregion

--#region NPC Interaction

--- Finds a nearby NPC that can be interacted with
function RbxNPCService:FindNearbyNPC(sourceNPCModel: Model, allNPCs: { any }): any?
	local sourceRoot = sourceNPCModel:FindFirstChild("HumanoidRootPart")
	if not sourceRoot then
		return nil
	end

	local sourcePosition = sourceRoot.Position
	local minRadius = Config.NPC_INTERACTION_DETECTION_RADIUS_MIN
	local maxRadius = Config.NPC_INTERACTION_DETECTION_RADIUS_MAX

	-- Shuffle NPCs for random selection
	local shuffledNPCs = shuffleArray(allNPCs)

	-- Find first available NPC in range
	for _, npc in ipairs(shuffledNPCs) do
		if npc.Model and npc.Model ~= sourceNPCModel then
			local targetRoot = npc.Model:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local distance = (sourcePosition - targetRoot.Position).Magnitude

				if distance >= minRadius and distance <= maxRadius and npc:CanInteractWithNPC() then
					return npc
				end
			end
		end
	end

	return nil
end

--- Makes two NPCs face each other for interaction
function RbxNPCService:MakeNPCsInteract(npc1Model: Model, npc2Model: Model)
	local root1 = npc1Model:FindFirstChild("HumanoidRootPart")
	local root2 = npc2Model:FindFirstChild("HumanoidRootPart")

	if not root1 or not root2 then
		return
	end

	local direction1to2 = (root2.Position - root1.Position).Unit
	local direction2to1 = (root1.Position - root2.Position).Unit

	local lookAt1 = CFrame.new(root1.Position, root1.Position + Vector3.new(direction1to2.X, 0, direction1to2.Z))
	local lookAt2 = CFrame.new(root2.Position, root2.Position + Vector3.new(direction2to1.X, 0, direction2to1.Z))

	root1.CFrame = lookAt1
	root2.CFrame = lookAt2

	if Config.DEBUG then
		print("[RbxNPCService]", npc1Model.Name, "and", npc2Model.Name, "are now facing each other")
	end
end

--#endregion

return RbxNPCService
