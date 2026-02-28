local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Parent.Config)

export type NPCEntity = {
	-- Identity
	Id: string, -- Unique identifier (GUID)
	Username: string,
	OutfitId: number, -- Reference to Outfits.lua
	OutfitName: string?, -- Reference to Outfits.lua

	-- Model Reference
	Model: Model?,
	Humanoid: Humanoid?,
	HumanoidRootPart: BasePart?,

	-- Health System
	Health: number,
	MaxHealth: number,
	IsAlive: boolean,

	-- Movement & Behavior
	State: string, -- "Idle", "Walking", "Observing", "Interacting", "Dead"
	SpawnPosition: Vector3,
	CurrentPosition: Vector3,
	TargetPosition: Vector3?,

	-- Timers
	StateStartTime: number,
	StateDuration: number, -- how long to stay in current state (seconds)

	-- Interaction (Player)
	CanInteract: boolean,
	InteractingWithPlayer: Player?,
	LastInteractionTime: number,

	-- NPC-to-NPC Interaction
	IsInteractingWithNPC: boolean,
	InteractionPartner: string?, -- ID of the NPC they're interacting with
	NPCInteractionCooldownUntil: number, -- Timestamp when interaction cooldown ends
	IsBusy: boolean,

	-- Gear
	GearId: number?,
	GearName: string?,
}

local NPCEntity = {}
NPCEntity.__index = NPCEntity

-- Create new NPC entity
function NPCEntity.new(data: {
	Username: string?,
	OutfitId: number,
	GearId: number?,
	SpawnPosition: Vector3,
	Health: number?,
	MaxHealth: number?,
}): NPCEntity
	local self = setmetatable({}, NPCEntity)

	-- Generate unique ID
	self.Id = HttpService:GenerateGUID(false)

	self.Username = data.Username or NPCEntity.GetRandomName()
	self.OutfitId = data.OutfitId
	self.GearId = data.GearId

	self.Model = nil
	self.Humanoid = nil
	self.HumanoidRootPart = nil

	self.MaxHealth = data.MaxHealth or Config.DEFAULT_MAX_HEALTH
	self.Health = data.Health or self.MaxHealth
	self.IsAlive = true

	self.State = Config.States.IDLE
	self.SpawnPosition = data.SpawnPosition
	self.CurrentPosition = data.SpawnPosition
	self.TargetPosition = nil

	self.StateStartTime = os.clock()
	self.StateDuration = math.random(Config.IDLE_DURATION_MIN, Config.IDLE_DURATION_MAX)

	self.CanInteract = true
	self.InteractingWithPlayer = nil
	self.LastInteractionTime = 0

	self.IsInteractingWithNPC = false
	self.InteractionPartner = nil
	self.NPCInteractionCooldownUntil = 0
	self.IsBusy = false

	self.GearName = nil
	self.OutfitName = nil

	return self
end

-- Get random name from config
function NPCEntity.GetRandomName(): string
	local names = Config.NPC_NAMES
	return names[math.random(1, #names)]
end

function NPCEntity:SetGearName(gearName: string)
	self.GearName = gearName
end

function NPCEntity:GetGearName(): string?
	return self.GearName
end

function NPCEntity:SetOutfitName(outfitName: string)
	self.OutfitName = outfitName
end

function NPCEntity:GetOutfitName(): string?
	return self.OutfitName
end

-- Set the NPC's state
function NPCEntity:SetState(newState: string, duration: number?)
	self.State = newState
	self.StateStartTime = os.clock()

	if duration then
		self.StateDuration = duration
	elseif newState == Config.States.WALKING then
		self.StateDuration = math.random(Config.WALK_DURATION_MIN, Config.WALK_DURATION_MAX)
	elseif newState == Config.States.RUNNING then
		self.StateDuration = math.random(Config.RUN_DURATION_MIN, Config.RUN_DURATION_MAX)
	elseif newState == Config.States.OBSERVING then
		self.StateDuration = math.random(Config.OBSERVE_DURATION_MIN, Config.OBSERVE_DURATION_MAX)
	elseif newState == Config.States.IDLE then
		self.StateDuration = math.random(Config.IDLE_DURATION_MIN, Config.IDLE_DURATION_MAX)
	else
		self.StateDuration = 0
	end
end

-- Check if NPC can transition to a new state
function NPCEntity:CanTransitionState(): boolean
	if not self.IsAlive then
		return false
	end

	local currentTime = os.clock()
	return (currentTime - self.StateStartTime) >= self.StateDuration
end

function NPCEntity:TakeDamage(amount: number): boolean
	if not self.IsAlive then
		return false
	end

	self.Health = math.max(0, self.Health - amount)

	if self.Health <= 0 then
		self:Die()
		return true
	end

	return false
end

-- Handle NPC death
function NPCEntity:Die()
	self.IsAlive = false
	self.State = Config.States.DEAD
	self.Health = 0
	self.CanInteract = false
	self.InteractingWithPlayer = nil
end

-- Update current position
function NPCEntity:UpdatePosition(position: Vector3)
	self.CurrentPosition = position
end

-- Check if can interact
function NPCEntity:CanBeInteracted(): boolean
	if not self.IsAlive or not self.CanInteract then
		return false
	end

	local currentTime = os.clock()
	return (currentTime - self.LastInteractionTime) >= Config.INTERACTION_COOLDOWN
end

-- Start interaction with player
function NPCEntity:StartInteraction(player: Player)
	self.InteractingWithPlayer = player
	self.LastInteractionTime = os.clock()
	self:SetState(Config.States.INTERACTING)
end

-- End interaction
function NPCEntity:EndInteraction()
	self.InteractingWithPlayer = nil
	self:SetState(Config.States.IDLE)
end

-- Check if NPC can interact with another NPC
function NPCEntity:CanInteractWithNPC(): boolean
	if not self.IsAlive or self.IsBusy or self.IsInteractingWithNPC then
		return false
	end

	local currentTime = os.clock()
	return currentTime >= self.NPCInteractionCooldownUntil
end

-- Start interaction with another NPC
function NPCEntity:StartNPCInteraction(partnerNPCId: string, duration: number)
	self.IsInteractingWithNPC = true
	self.InteractionPartner = partnerNPCId
	self:SetState(Config.States.INTERACTING, duration)
end

-- End NPC interaction and set cooldown
function NPCEntity:EndNPCInteraction()
	self.IsInteractingWithNPC = false
	self.InteractionPartner = nil

	local cooldown = math.random(Config.NPC_INTERACTION_COOLDOWN_MIN, Config.NPC_INTERACTION_COOLDOWN_MAX)
	self.NPCInteractionCooldownUntil = os.clock() + cooldown

	self:SetState(Config.States.IDLE)
end

-- Set whether NPC is busy (e.g., pathfinding)
function NPCEntity:SetBusy(busy: boolean)
	self.IsBusy = busy
end

function NPCEntity:GetState()
	return self.State
end

return NPCEntity
