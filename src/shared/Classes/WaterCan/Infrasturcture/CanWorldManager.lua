--[[
    CanWorldManager  (Machine/Infrastructure)
    ───────────────────────────────────────────
    Manages the physical watering can objects that appear inside machines.

    For every filled machine slot, a Part (the "world can") sits at the
    slot's attachment point with a ProximityPrompt on it.
    When a player presses E, the ProximityPrompt fires a pickup callback.

    ── Studio Setup ────────────────────────────────────────────────────────────
    Each machine Model should have Attachments named:
        Slot1, Slot2, Slot3, ...  (one per max slot count)

    These mark where the can Parts are positioned.
    If an attachment is missing, the can falls back to the machine's
    PrimaryPart CFrame with a stacked Y offset.

    ── Can Template ────────────────────────────────────────────────────────────
    Optional: place a Part or Model named "CanTemplate" inside
    ReplicatedStorage.  CanWorldManager will clone it for each slot.
    If missing, it creates a default coloured cylinder Part.

    ── Callback ────────────────────────────────────────────────────────────────
    Call   canWorldManager:SetPickupCallback(fn)
    where  fn = function(player, machineId, slotIndex) end
    This is called by MachineService to wire the pickup use case.
--]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- ── Constants ─────────────────────────────────────────────────────────────────
local PROMPT_KEY = Enum.KeyCode.E
local PROMPT_ACTION_TEXT = "Pick Up"
local PROMPT_HOLD_DURATION = 0 -- instant press (set > 0 for hold-to-pickup)
local CAN_SIZE = Vector3.new(0.4, 0.7, 0.4)
local CAN_COLOR = Color3.fromRGB(72, 160, 220)
local CAN_Y_OFFSET = Vector3.new(0, 0.5, 0) -- lift above slot attachment
local SLOT_STACK_OFFSET = 0.5 -- fallback Y gap when no attachments

-- ── Module ────────────────────────────────────────────────────────────────────

local CanWorldManager = {}
CanWorldManager.__index = CanWorldManager

function CanWorldManager.new()
	return setmetatable({
		-- _parts[machineId][slotIndex] = BasePart
		_parts = {},
		_pickupCallback = nil,
	}, CanWorldManager)
end

-- ── Public API ────────────────────────────────────────────────────────────────

--- Register a callback invoked when a player presses E on a can.
--- signature: function(player: Player, machineId: string, slotIndex: number)
function CanWorldManager:SetPickupCallback(fn: (Player, string, number) -> ())
	self._pickupCallback = fn
end

--- Call after a machine is registered. Creates a world folder for it.
function CanWorldManager:InitMachine(machineId: string)
	if not self._parts[machineId] then
		self._parts[machineId] = {}
	end
end

--- Spawns a can Part at the given slot position (or attachment).
--- Call this when a new can is inserted into a slot.
function CanWorldManager:SpawnCanPart(
	machineId: string,
	slotIndex: number,
	machineModel: Model? -- the workspace Model (for attachment lookup)
)
	self:RemoveCanPart(machineId, slotIndex) -- clean up if one already exists

	local cf = self:_GetSlotCFrame(machineModel, slotIndex)

	-- Clone template or build default
	local part = self:_BuildCanPart()
	part.CFrame = cf + CAN_Y_OFFSET
	part.Name = string.format("WateringCan_%s_Slot%d", machineId, slotIndex)
	part.Parent = Workspace

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.KeyboardKeyCode = PROMPT_KEY
	prompt.ActionText = PROMPT_ACTION_TEXT
	prompt.HoldDuration = PROMPT_HOLD_DURATION
	prompt.MaxActivationDistance = 8
	prompt.Parent = part

	-- Wire the trigger
	local capturedMachineId = machineId
	local capturedSlotIndex = slotIndex
	prompt.Triggered:Connect(function(triggeringPlayer: Player)
		if self._pickupCallback then
			self._pickupCallback(triggeringPlayer, capturedMachineId, capturedSlotIndex)
		end
	end)

	if not self._parts[machineId] then
		self._parts[machineId] = {}
	end
	self._parts[machineId][slotIndex] = part
end

--- Removes the can Part from a slot (called on pickup or machine removal).
function CanWorldManager:RemoveCanPart(machineId: string, slotIndex: number)
	local parts = self._parts[machineId]
	if not parts then
		return
	end

	local part = parts[slotIndex]
	if part then
		part:Destroy()
		parts[slotIndex] = nil
	end
end

--- Removes all can Parts for a machine (called when machine is unregistered).
function CanWorldManager:RemoveAllParts(machineId: string)
	local parts = self._parts[machineId]
	if not parts then
		return
	end

	for slotIndex in pairs(parts) do
		self:RemoveCanPart(machineId, slotIndex)
	end
	self._parts[machineId] = nil
end

-- ── Held can Tool ──────────────────────────────────────────────────────────────

--- Creates a Tool and places it in the player's backpack.
--- The Tool carries canId as an attribute so the server can track it.
---@param player   Player
---@param canId    string
---@param level    number
---@param tierName string
function CanWorldManager:GiveCanTool(player: Player, canId: string, level: number, tierName: string)
	local tool = Instance.new("Tool")
	tool.Name = "WateringCan"
	tool.ToolTip = string.format("Lv.%d %s", level, tierName)
	tool.RequiresHandle = true
	tool:SetAttribute("CanId", canId)
	tool:SetAttribute("CanLevel", level)
	tool:SetAttribute("TierName", tierName)

	-- Handle (the visible part held by the player)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = CAN_SIZE
	handle.Color = CAN_COLOR
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool

	-- Simple mesh to look like a can
	local mesh = Instance.new("CylinderMesh")
	mesh.Parent = handle

	tool.Parent = player.Backpack
	return tool
end

-- ── Private helpers ───────────────────────────────────────────────────────────

function CanWorldManager:_GetSlotCFrame(machineModel: Model?, slotIndex: number): CFrame
	if machineModel then
		local attachment = machineModel:FindFirstChild("Slot" .. slotIndex, true)
		if attachment and attachment:IsA("Attachment") then
			return attachment.WorldCFrame
		end
		-- Fallback: stack above PrimaryPart
		local primary = machineModel.PrimaryPart or machineModel:FindFirstChildWhichIsA("BasePart")
		if primary then
			return primary.CFrame + Vector3.new(0, SLOT_STACK_OFFSET * slotIndex, 0)
		end
	end
	-- Last resort: world origin (shouldn't happen in a properly set-up game)
	return CFrame.new(0, SLOT_STACK_OFFSET * slotIndex, 0)
end

function CanWorldManager:_BuildCanPart(): Part
	-- Try to clone a template from ReplicatedStorage
	local template = RS:FindFirstChild("CanTemplate")
	if template and template:IsA("BasePart") then
		local clone = template:Clone()
		clone.Anchored = true
		return clone
	end

	-- Default: cyan cylinder
	local part = Instance.new("Part")
	part.Size = CAN_SIZE
	part.Color = CAN_COLOR
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	local mesh = Instance.new("CylinderMesh")
	mesh.Parent = part
	return part
end

return CanWorldManager
