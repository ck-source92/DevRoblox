--[[
    MachineService  (ServerScriptService)
    ──────────────────────────────────────
    Knit service. Thin layer over machine use cases.

    Responsibilities:
      • Own the MachineRepository instance
      • Discover tagged Machine models via CollectionService
      • Run the 1-second tick loop via MachineTickUseCase
      • Fire client signals from tick results
      • Expose InsertCan / RemoveCan / UpgradeMachine to client
--]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Infrastructure
local MachineRepository = require(RS.Shared.Classes.Machine.Infrastructure.MachineRepository)
local MachineRegistry = require(RS.Shared.Classes.Machine.Infrastructure.MachineRegistry)
-- Domain
local MachineEntity = require(RS.Shared.Classes.Machine.Domain.MachineEntity)
-- Application
local InsertCanUseCase = require(RS.Shared.Classes.Machine.Applications.InsertCanUseCase)
local RemoveCanUseCase = require(RS.Shared.Classes.Machine.Applications.RemoveCanUsecase)
local PickupCanUseCase = require(RS.Shared.Classes.WaterCan.Applications.PickUpCanUseCase)
local AutoRefillUseCase = require(RS.Shared.Classes.Machine.Applications.AutoRefillUseCase)
local UpgradeMachineUseCase = require(RS.Shared.Classes.Machine.Applications.UpgradeMachineUsecase)
local CanWorldManager = require(RS.Shared.Classes.WaterCan.Infrasturcture.CanWorldManager)
local MachineTickUseCase = require(RS.Shared.Classes.Machine.Applications.MachineTickUseCase)
local MachineResolver = require(RS.Shared.Classes.Machine.Applications.MachineResolver)
local AddXPUseCase = require(RS.Shared.Classes.WaterCan.Applications.AddXPUseCase)

local RbxWaterCanService = require(RS.Shared.Classes.WaterCan.RbxWaterCanService)
local RbxMachineService = require(RS.Shared.Classes.Machine.RbxMachineService)

-- Data
local WateringCanData = require(RS.Shared.Data.WateringCanData)

local MACHINE_TAG = "Machine"
local TICK_INTERVAL = 1

local DEBUG_MODE = false
local function DebugLog(...)
	if DEBUG_MODE then
		print("[MachineService DEBUG]", ...)
	end
end

local MachineService = Knit.CreateService({
	Name = "MachineService",
	Client = {
		MachineStateUpdated = Knit.CreateSignal(), -- (machineId, snapshot)
		UpgradeResult = Knit.CreateSignal(), -- (machineId, success, newLevel)
		SlotChanged = Knit.CreateSignal(), -- (machineId, slotIndex, slotData|nil)
		CanPickedUp = Knit.CreateSignal(), -- (machineId, slotIndex, canId)
		SlotRefilled = Knit.CreateSignal(), -- (machineId, slotIndex, newCanId)
	},
})

local _machineRepo: table
local _canWorldMgr: table
local _pickupUC: table
local _autoRefillUC: table

-- machineId → workspace Model
local _modelMap: { [string]: Model } = {}

local _idCounter = 0
local function _newId(): string
	_idCounter = _idCounter + 1
	return "machine_" .. _idCounter
end

-- ── Machine snapshot builder ──────────────────────────────────────────────────

local function _snapshot(machine: table): table
	local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
	return {
		machineId = machine.machineId,
		machineType = machine.machineType,
		upgradeLevel = machine.upgradeLevel,
		maxUpgrade = profile.maxUpgrade,
		slotCount = profile.slotCount,
		xpPerTick = profile.xpPerTick,
		displayName = profile.displayName,
		slots = machine.slots,
	}
end

-- ── Slot world spawn helper ───────────────────────────────────────────────────
local function _spawnSlotPart(machineId: string, slotIndex: number)
	local model = _modelMap[machineId]
	_canWorldMgr:SpawnCanPart(machineId, slotIndex, model)
end

-- ── Pickup handler (wired from CanWorldManager callback) ──────────────────────
local function _onPickup(player: Player, machineId: string, slotIndex: number)
	-- 1. Pick up the can
	local pickupResult = _pickupUC:Execute(player, machineId, slotIndex)
	if not pickupResult.success then
		warn("[MachineService] Pickup failed:", pickupResult.message)
		return
	end

	local canId = pickupResult.canId
	local can = pickupResult.can

	DebugLog(string.format("Pickup  player=%s  machine=%s  slot=%d  can=%s", player.Name, machineId, slotIndex, canId))

	-- 2. Remove the world Part for that slot
	_canWorldMgr:RemoveCanPart(machineId, slotIndex)

	-- 3. Give the player a Tool representing the can
	local tierName = WateringCanData.GetTierName(can.level)
	_canWorldMgr:GiveCanTool(player, canId, can.level, tierName)

	-- 4. Fire pickup signal to client
	MachineService.Client.CanPickedUp:Fire(player, machineId, slotIndex, canId)
	MachineService.Client.SlotChanged:FireAll(machineId, slotIndex, nil)

	-- 5. Auto-refill: create a fresh can in the now-empty slot
	local refillResult = _autoRefillUC:Execute(player, machineId, slotIndex)
	if refillResult.success then
		DebugLog(
			string.format("AutoRefill  machine=%s  slot=%d  newCan=%s", machineId, slotIndex, refillResult.newCanId)
		)

		-- 6. Spawn the new world Part
		_spawnSlotPart(machineId, slotIndex)

		-- 7. Notify clients
		local machine = _machineRepo:GetMachine(machineId)
		MachineService.Client.SlotChanged:FireAll(machineId, slotIndex, machine.slots[slotIndex])
		MachineService.Client.SlotRefilled:Fire(player, machineId, slotIndex, refillResult.newCanId)
	else
		warn("[MachineService] AutoRefill failed:", refillResult.message)
	end
end

-- ── CollectionService wiring ──────────────────────────────────────────────────

local function _register(model: Model)
	local machineType = model:GetAttribute("MachineType")
	if not machineType or not MachineRegistry.Has(machineType) then
		warn("[MachineService] Invalid or missing MachineType on:", model:GetFullName())
		return
	end
	local machineId = _newId()
	model:SetAttribute("MachineId", machineId)
	_machineRepo:RegisterMachine(MachineEntity.new(machineId, machineType, 0))
	_modelMap[machineId] = model
	_canWorldMgr:InitMachine(machineId)
end

local function _unregister(model: Model)
	local machineId = model:GetAttribute("MachineId")
	if machineId then
		_machineRepo:UnregisterMachine(machineId)
	end
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function MachineService:KnitInit()
	self.WaterCanService = Knit.GetService("WaterCanService")

	_machineRepo = MachineRepository.new()
	_canWorldMgr = CanWorldManager.new()
	self._upgradeUC = UpgradeMachineUseCase.new(_machineRepo)

	_canWorldMgr:SetPickupCallback(_onPickup)

	for _, model in ipairs(CollectionService:GetTagged(MACHINE_TAG)) do
		_register(model)
	end
	CollectionService:GetInstanceAddedSignal(MACHINE_TAG):Connect(_register)
	CollectionService:GetInstanceRemovedSignal(MACHINE_TAG):Connect(_unregister)
end

function MachineService:KnitStart()
	self._insertUC = InsertCanUseCase.new(_machineRepo, self.WaterCanService:GetRepo())
	self._removeUC = RemoveCanUseCase.new(_machineRepo, self.WaterCanService)
	_pickupUC = PickupCanUseCase.new(_machineRepo, self.WaterCanService:GetRepo())
	_autoRefillUC = AutoRefillUseCase.new(_machineRepo, self.WaterCanService:GetRepo())
	self._tickUC = MachineTickUseCase.new(_machineRepo, AddXPUseCase.new(self.WaterCanService:GetRepo()))

	if DEBUG_MODE then
		print("[MachineService] DEBUG MODE ENABLED - verbose logging active")
		RbxWaterCanService.Run({
			totalTicks = 15,
			tickInterval = 0, -- 0 = instant (no task.wait), great for quick tests
			printEvery = 5,
			debugMode = DEBUG_MODE,
			xpPerCan = { [1] = 5, [2] = 12, [3] = 30 },
		})

		RbxMachineService.Run({
			totalTicks = 20,
			tickInterval = 0,
			printEvery = 5,
			debugMode = DEBUG_MODE,
			-- Tighter upgrades so they're visible in a short run
			upgrades = {
				{ tick = 5, machineId = "pump_01", label = "HandPump   → Tier 1" },
				{ tick = 10, machineId = "wheel_01", label = "WaterWheel → Tier 1" },
				{ tick = 15, machineId = "pump_01", label = "HandPump   → Tier 2" },
			},
		})
	end

	-- Fill machines when a player joins
	Players.PlayerAdded:Connect(function(player)
		-- Small wait so WateringCanService:KnitStart has initialised the player
		task.wait(0.1)
		MachineService:FillMachinesForPlayer(player)
	end)

	-- Also fill for any player already in the game
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(0.1)
			MachineService:FillMachinesForPlayer(player)
		end)
	end

	-- Tick loop
	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			local ok, err = pcall(function()
				local results = _tickUC:Execute()
				for _, r in ipairs(results) do
					DebugLog(
						string.format(
							"tick  machine=%-12s  can=%-8s  +%6.0f XP  lvl=%-3d  levelUps=%d",
							r.machineId,
							r.canId,
							r.xpApplied,
							r.newLevel,
							r.levelUps
						)
					)
				end
			end)
			if not ok then
				warn("[MachineService] Tick error:", err)
			end
		end
	end)
end

--#region  Client APIs

function MachineService.Client:GetAllMachines(player: Player): table
	local result = {}
	for machineId, machine in pairs(_machineRepo:GetAllMachines()) do
		result[machineId] = _snapshot(machine)
	end
	return result
end

function MachineService.Client:InsertCan(player: Player, machineId: string, canId: string): table
	return MachineService:InsertCan(player, machineId, canId)
end

function MachineService.Client:RemoveCan(player: Player, machineId: string, canId: string): table
	return MachineService:RemoveCan(player, machineId, canId)
end

function MachineService.Client:UpgradeMachine(player: Player, machineId: string): table
	return MachineService:UpgradeMachine(player, machineId)
end
--#endregion

--#region Public API

function MachineService:InsertCan(player: Player, machineId: string, canId: string): table
	local result = self._insertUC:Execute(player, machineId, canId)
	if result.success then
		local machine = _machineRepo:GetMachine(machineId)
		self.Client.SlotChanged:FireAll(machineId, result.slotIndex, machine.slots[result.slotIndex])
	end
	return result
end

function MachineService:RemoveCan(player: Player, machineId: string, canId: string): table
	local result = self._removeUC:Execute(player, machineId, canId)
	if result.success then
		self.Client.SlotChanged:FireAll(machineId, result.slotIndex, nil)
	end
	return result
end

function MachineService:UpgradeMachine(player: Player, machineId: string): table
	local result = self._upgradeUC:Execute(player, machineId)
	if result.success then
		local machine = _machineRepo:GetMachine(machineId)
		local snap = _snapshot(machine)
		self.Client.MachineStateUpdated:FireAll(machineId, snap)
		self.Client.UpgradeResult:Fire(player, machineId, true, result.newUpgradeLevel)
	end
	return result
end

function MachineService:FillMachinesForPlayer(player: Player)
	for machineId, machine in pairs(_machineRepo:GetAllMachines()) do
		local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
		for slotIndex = 1, profile.slotCount do
			if not machine.slots[slotIndex] then
				local result = _autoRefillUC:Execute(player, machineId, slotIndex)
				if result.success then
					_spawnSlotPart(machineId, slotIndex)
					MachineService.Client.SlotChanged:FireAll(machineId, slotIndex, machine.slots[slotIndex])
				end
			end
		end
	end
end
--#endregion

return MachineService
