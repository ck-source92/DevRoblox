--[[
    WateringCanController  (StarterPlayerScripts)
    ──────────────────────────────────────────────
    Knit controller. Mirrors the player's can inventory and tracks
    which can the player is currently holding as a Tool.

    ── Held can tracking ────────────────────────────────────────────────────────
    When a player picks up a can, MachineService:GiveCanTool() places a
    Tool in their Backpack. This controller detects when the Tool is
    equipped / unequipped and exposes the held can's state.

    ── UI Callbacks ─────────────────────────────────────────────────────────────
    OnCanUpdated      (canId, canData)              — any XP change
    OnCanLeveledUp    (canId, newLevel, tierName)   — level-up event
    OnCanEquipped     (canId, canData)              — player holds the can
    OnCanUnequipped   (canId)                       — player puts it away
--]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LevelUtil = require(RS.Shared.Modules.LevelUtil)
local WateringCanData = require(RS.Shared.Data.WateringCanData)

local LocalPlayer = Players.LocalPlayer

local WaterCanController = Knit.CreateController({
	Name = "WateringCanController",
	Client = {},

	-- UI Callbacks
	OnCanUpdated = nil, -- (canId, canData)
	OnCanLeveledUp = nil, -- (canId, newLevel, tierName)
	OnCanEquipped = nil, -- (canId, canData)
	OnCanUnequipped = nil, -- (canId)
})

-- ── Local mirror (plain serialized tables, not entities) ──────────────────────
local _inventory: { [string]: table } = {}
local _heldCanId: string? = nil

-- ── Tool equip / unequip tracking ─────────────────────────────────────────────
local function _onToolEquipped(tool: Tool)
	local canId = tool:GetAttribute("CanId")
	local canLevel = tool:GetAttribute("CanLevel")
	local tierName = tool:GetAttribute("TierName")

	if not canId then
		return
	end

	_heldCanId = canId
	print(string.format("[WateringCan] 🫙  Equipped  can=%-8s  Lv.%d  %s", canId, canLevel or 1, tierName or "?"))

	if WaterCanController.OnCanEquipped then
		WaterCanController.OnCanEquipped(canId, _inventory[canId])
	end
end

local function _onToolUnequipped(tool: Tool)
	local canId = tool:GetAttribute("CanId")
	if not canId then
		return
	end

	if _heldCanId == canId then
		_heldCanId = nil
	end

	print(string.format("[WateringCan] 🫙  Unequipped  can=%s", canId))

	if WaterCanController.OnCanUnequipped then
		WaterCanController.OnCanUnequipped(canId)
	end
end

-- Watch the character's Humanoid for equip/unequip
local function _watchCharacter(character: Model)
	-- Check already-held tools
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("CanId") then
			_onToolEquipped(child)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("CanId") then
			_onToolEquipped(child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("CanId") then
			_onToolUnequipped(child)
		end
	end)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function WaterCanController:KnitInit()
	self.WaterCanService = Knit.GetService("WaterCanService")
end

function WaterCanController:KnitStart()
	-- Initial inventory sync
	local ok, inv = pcall(function()
		return self.WaterCanService:GetInventory()
	end)
	if ok and inv then
		_inventory = inv
	end

	-- Live XP stream
	self.WaterCanService.CanXPUpdated:Connect(function(canId, newXP, newLevel)
		local can = _inventory[canId]
		if can then
			can.currentXP = newXP
			can.level = newLevel
		else
			_inventory[canId] = { canId = canId, level = newLevel, currentXP = newXP }
		end
		if WaterCanController.OnCanUpdated then
			WaterCanController.OnCanUpdated(canId, _inventory[canId])
		end
	end)

	-- Level-up event
	self.WaterCanService.CanLeveledUp:Connect(function(canId, newLevel, tierName)
		if WaterCanController.OnCanLeveledUp then
			WaterCanController.OnCanLeveledUp(canId, newLevel, tierName)
		end
		print(string.format("[WateringCan] 🌟 %s → Lv.%d (%s)", canId, newLevel, tierName))
	end)

	-- Full resync
	self.WaterCanService.InventorySync:Connect(function(snapshot)
		_inventory = snapshot
		if WaterCanController.OnCanUpdated then
			for canId, can in pairs(_inventory) do
				WaterCanController.OnCanUpdated(canId, can)
			end
		end
	end)

	-- Watch character for tool equip / unequip
	if LocalPlayer.Character then
		_watchCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(_watchCharacter)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function WaterCanController:GetInventory(): { [string]: table }
	return _inventory
end

function WaterCanController:GetCan(canId: string): table?
	return _inventory[canId]
end

--- Returns the canId the player is currently holding, or nil.
function WaterCanController:GetHeldCanId(): string?
	return _heldCanId
end

--- Returns the held can's state table, or nil.
function WaterCanController:GetHeldCan(): table?
	return _heldCanId and _inventory[_heldCanId]
end

function WaterCanController:GetProgress(canId: string): number
	local can = _inventory[canId]
	if not can then
		return 0
	end
	return LevelUtil.GetProgress(WateringCanData.LevelTable, can.level, can.currentXP)
end

function WaterCanController:GetProgressString(canId: string): string
	local can = _inventory[canId]
	if not can then
		return "? / ?"
	end
	return LevelUtil.GetProgressString(WateringCanData.LevelTable, can.level, can.currentXP)
end

function WaterCanController:GetTierName(canId: string): string
	local can = _inventory[canId]
	return can and WateringCanData.GetTierName(can.level) or "Unknown"
end

return WaterCanController
