--[[
    MachineController  (StarterPlayerScripts)
    ──────────────────────────────────────────
    Knit controller. Mirrors machine snapshots and handles client-side
    pickup feedback + slot refill notifications.

    ── New signals handled ───────────────────────────────────────────────────────
    CanPickedUp    → fired on the picking player only
                     triggers pickup animation, sound, UI notification
    SlotRefilled   → fired on the picking player only after auto-refill
                     triggers refill animation / "new can ready" notification
--]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RS = game:GetService("ReplicatedStorage")
local MachineResolver = require(RS.Shared.Classes.Machine.Applications.MachineResolver)

local MachineController = Knit.CreateController({
	Name = "MachineController",
	Client = {},

	-- ── UI Callbacks ──────────────────────────────────────────────────────────────
	OnMachineUpdated = nil, -- (machineId, snapshot)
	OnSlotChanged = nil, -- (machineId, slotIndex, slotData|nil)
	OnUpgradeResult = nil, -- (machineId, success, newTier)
	OnCanPickedUp = nil, -- (machineId, slotIndex, canId)
	OnSlotRefilled = nil, -- (machineId, slotIndex, newCanId)
})

-- ── Local mirror of machine snapshots ────────────────────────────────────────
local _snapshots: { [string]: table } = {}

-- ── Public API ────────────────────────────────────────────────────────────────

function MachineController:GetSnapshot(machineId: string): table?
	return _snapshots[machineId]
end

function MachineController:GetAllSnapshots(): { [string]: table }
	return _snapshots
end

--- e.g. "Steam Filler  |  Tier 1/4  |  60 XP/s  |  Slots: 2/3"
function MachineController:GetInfoString(machineId: string): string
	local s = _snapshots[machineId]
	if not s then
		return "Unknown Machine"
	end
	local used = 0
	for i = 1, s.slotCount do
		if s.slots[i] then
			used = used + 1
		end
	end
	return string.format(
		"%s  |  Tier %d/%d  |  %.0f XP/s  |  Slots: %d/%d",
		s.displayName,
		s.upgradeLevel,
		s.maxUpgrade,
		s.xpPerTick,
		used,
		s.slotCount
	)
end

function MachineController:GetNextUpgradeCost(machineId: string): number?
	local s = _snapshots[machineId]
	if not s then
		return nil
	end
	return MachineResolver:GetNextUpgradeCost(s.machineType, s.upgradeLevel)
end

-- ── Remote Actions ────────────────────────────────────────────────────────────

function MachineController:InsertCan(machineId: string, canId: string): table
	local ok, msg = self.MachineService:InsertCan(machineId, canId)
	if not ok then
		warn("[MachineController] InsertCan:", msg)
	end
	return ok, msg
end

function MachineController:RemoveCan(machineId: string, canId: string): table
	local ok, msg = self.MachineService:RemoveCan(machineId, canId)
	if not ok then
		warn("[MachineController] RemoveCan:", msg)
	end
	return ok, msg
end

function MachineController:UpgradeMachine(machineId: string): table
	local ok, msg = self.MachineService:UpgradeMachine(machineId)
	if not ok then
		warn("[MachineController] UpgradeMachine:", msg)
	end
	return ok, msg
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function MachineController:KnitInit() end

function MachineController:KnitStart()
	self.MachineService = Knit.GetService("MachineService")

	-- Initial snapshot fetch
	local ok, all = pcall(function()
		return self.MachineService:GetAllMachines()
	end)
	if ok and all then
		_snapshots = all
	end

	-- Machine state (upgrades change XP/slot stats)
	self.MachineService.MachineStateUpdated:Connect(function(machineId, snapshot)
		_snapshots[machineId] = snapshot
		if MachineController.OnMachineUpdated then
			MachineController.OnMachineUpdated(machineId, snapshot)
		end
	end)

	-- Slot changed (insert / remove / refill)
	self.MachineService.SlotChanged:Connect(function(machineId, slotIndex, slotData)
		local snap = _snapshots[machineId]
		if snap then
			snap.slots[slotIndex] = slotData
		end
		if MachineController.OnSlotChanged then
			MachineController.OnSlotChanged(machineId, slotIndex, slotData)
		end
	end)

	-- Upgrade result
	self.MachineService.UpgradeResult:Connect(function(machineId, success, newTier)
		if MachineController.OnUpgradeResult then
			MachineController.OnUpgradeResult(machineId, success, newTier)
		end
		if success then
			print(string.format("[Machine] ⬆ %s → Tier %d", machineId, newTier))
		end
	end)

	-- ── Water Can picked up
	self.MachineService.CanPickedUp:Connect(function(machineId, slotIndex, canId)
		print(string.format("[Machine] 🫙  Picked up  can=%-8s  machine=%s  slot=%d", canId, machineId, slotIndex))
		-- Update local slot mirror
		local snap = _snapshots[machineId]
		if snap then
			snap.slots[slotIndex] = nil
		end

		if MachineController.OnCanPickedUp then
			MachineController.OnCanPickedUp(machineId, slotIndex, canId)
		end
		-- Hook example: play pickup sound, show "Can picked up!" toast, etc.
	end)

	-- ── Slot refilled
	self.MachineService.SlotRefilled:Connect(function(machineId, slotIndex, newCanId)
		print(
			string.format("[Machine] 🔄  Auto-refill  machine=%s  slot=%d  newCan=%s", machineId, slotIndex, newCanId)
		)

		if MachineController.OnSlotRefilled then
			MachineController.OnSlotRefilled(machineId, slotIndex, newCanId)
		end
		-- Hook example: show "New can ready" indicator on the machine UI
	end)
end

return MachineController
