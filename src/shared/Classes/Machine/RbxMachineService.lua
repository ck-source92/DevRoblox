--[[
    RbxMachineService  (ModuleScript)
    ───────────────────────────────────
    Full Machine → WateringCan XP simulation module.
    No Knit, no Players, no CollectionService.

    Usage:
        local Sim = require(path.RbxMachineService)
        Sim.Run()                              -- default config
        Sim.Run({ totalTicks = 30, debugMode = true })

    Config options (all optional):
        totalTicks    number    Ticks to simulate                (default 60)
        tickInterval  number    Seconds between ticks            (default 1)
        printEvery    number    Print status every N ticks       (default 5)
        debugMode     boolean   Print every tick XP event        (default false)
        machines      table     Array of { id, machineType }     (default below)
        canSlots      table     Array of { machineId, headStart? }
        upgrades      table     Array of { tick, machineId, label }
--]]

local RS = game:GetService("ReplicatedStorage")

-- Infrastructure
local WateringCanRepository = require(RS.Shared.Classes.WaterCan.Infrasturcture.WaterCanRepository)
local MachineRepository = require(RS.Shared.Classes.Machine.Infrastructure.MachineRepository)
-- Domain
local MachineEntity = require(RS.Shared.Classes.Machine.Domain.MachineEntity)
-- Application
local CreateCanUseCase = require(RS.Shared.Classes.WaterCan.Applications.CreateCanUseCase)
local AddXPUseCase = require(RS.Shared.Classes.WaterCan.Applications.AddXPUseCase)
local InsertCanUseCase = require(RS.Shared.Classes.Machine.Applications.InsertCanUseCase)
local UpgradeMachineUseCase = require(RS.Shared.Classes.Machine.Applications.UpgradeMachineUsecase)
local MachineTickUseCase = require(RS.Shared.Classes.Machine.Applications.MachineTickUseCase)
local MachineResolver = require(RS.Shared.Classes.Machine.Applications.MachineResolver)
-- Data
local WateringCanData = require(RS.Shared.Data.WateringCanData)

-- ── Defaults ──────────────────────────────────────────────────────────────────

local DEFAULTS = {
	totalTicks = 60,
	tickInterval = 1,
	printEvery = 5,
	debugMode = false,

	machines = {
		{ id = "pump_01", machineType = "HandPump" },
		{ id = "wheel_01", machineType = "WaterWheel" },
		{ id = "steam_01", machineType = "SteamFiller" },
	},

	canSlots = {
		{ machineId = "pump_01" },
		{ machineId = "wheel_01" },
		{ machineId = "wheel_01" },
		{ machineId = "steam_01" },
		{ machineId = "steam_01", headStart = 90 }, -- near level-up
	},

	upgrades = {
		{ tick = 10, machineId = "pump_01", label = "HandPump   → Tier 1" },
		{ tick = 20, machineId = "wheel_01", label = "WaterWheel → Tier 1" },
		{ tick = 35, machineId = "pump_01", label = "HandPump   → Tier 2" },
		{ tick = 50, machineId = "steam_01", label = "SteamFiller → Tier 1" },
	},
}

-- ── Render helpers ────────────────────────────────────────────────────────────

local BAR_WIDTH = 22
local function Bar(p)
	local f = math.floor(p * BAR_WIDTH)
	return "[" .. string.rep("█", f) .. string.rep("░", BAR_WIDTH - f) .. "]"
end
local function Sep(c, n)
	return string.rep(c or "─", n or 66)
end

local function LevelUpBanner(canId, level)
	print("")
	print(
		"  ╔══════════════════════════════════════════════╗"
	)
	print(string.format("  ║  🌟  LEVEL UP!  %-30s║", ""))
	print(string.format("  ║  %-10s  →  Lv.%-3d  %-22s║", canId, level, WateringCanData.GetTierName(level)))
	print(
		"  ╚══════════════════════════════════════════════╝"
	)
	print("")
end

-- ── Module ────────────────────────────────────────────────────────────────────

local RbxMachineService = {}

function RbxMachineService.Run(cfg)
	local config = {}
	for k, v in pairs(DEFAULTS) do
		config[k] = v
	end
	if cfg then
		for k, v in pairs(cfg) do
			config[k] = v
		end
	end

	-- Wire repos and use cases
	local canRepo = WateringCanRepository.new()
	local machineRepo = MachineRepository.new()

	local createUC = CreateCanUseCase.new(canRepo)
	local addXPUC = AddXPUseCase.new(canRepo)
	local insertUC = InsertCanUseCase.new(machineRepo, canRepo)
	local upgradeUC = UpgradeMachineUseCase.new(machineRepo)
	local tickUC = MachineTickUseCase.new(machineRepo, addXPUC)

	local PLAYER = { Name = "SimPlayer", UserId = 0 }
	canRepo:InitPlayer(PLAYER)

	-- Register machines
	for _, def in ipairs(config.machines) do
		machineRepo:RegisterMachine(MachineEntity.new(def.id, def.machineType, 0))
	end

	-- Create and slot cans
	local canIds = {}
	for _, slot in ipairs(config.canSlots) do
		local can = createUC:Execute(PLAYER)
		if slot.headStart then
			can:ApplyXP(slot.headStart)
			canRepo:SaveCan(PLAYER, can)
		end
		table.insert(canIds, can.canId)
		insertUC:Execute(PLAYER, slot.machineId, can.canId)
	end

	-- Upgrade schedule lookup
	local byTick = {}
	for _, ev in ipairs(config.upgrades) do
		byTick[ev.tick] = byTick[ev.tick] or {}
		table.insert(byTick[ev.tick], ev)
	end

	-- Header
	print(Sep("═"))
	print("  [RbxMachineService]  MACHINE → CAN FILL SIMULATION")
	print(
		string.format(
			"  Ticks: %d  ·  Interval: %ds  ·  Machines: %d  ·  Cans: %d  ·  Debug: %s",
			config.totalTicks,
			config.tickInterval,
			#config.machines,
			#config.canSlots,
			tostring(config.debugMode)
		)
	)
	print(Sep("═"))

	for tick = 1, config.totalTicks do
		-- Scheduled upgrades
		if byTick[tick] then
			for _, ev in ipairs(byTick[tick]) do
				local result = upgradeUC:Execute(PLAYER, ev.machineId)
				if result.success then
					local profile = MachineResolver:Resolve(
						machineRepo:GetMachine(ev.machineId).machineType,
						machineRepo:GetMachine(ev.machineId).upgradeLevel
					)
					print(
						string.format(
							"  ⬆  Tick %2d  │  %s  │  now %.0f XP/tick  │  cost: %s coins",
							tick,
							ev.label,
							profile.xpPerTick,
							tostring(result.cost)
						)
					)
				end
			end
		end

		-- Tick
		local results = tickUC:Execute()
		for _, r in ipairs(results) do
			if config.debugMode then
				print(
					string.format(
						"  [DEBUG] tick=%-3d  machine=%-10s  can=%-8s  +%6.0f XP  lvl=%-3d  xp=%d",
						tick,
						r.machineId,
						r.canId,
						r.xpApplied,
						r.newLevel,
						r.newXP
					)
				)
			end
			if r.levelUps > 0 then
				LevelUpBanner(r.canId, r.newLevel)
			end
		end

		-- Status print
		if tick % config.printEvery == 0 or tick == 1 or tick == config.totalTicks then
			print(Sep("─"))
			print(string.format("  Tick %3d / %d", tick, config.totalTicks))
			print(Sep("─"))

			for _, def in ipairs(config.machines) do
				local machine = machineRepo:GetMachine(def.id)
				local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
				local tierStr = machine.upgradeLevel > 0
						and ("Tier " .. machine.upgradeLevel .. "/" .. profile.maxUpgrade)
					or "Base"

				print(
					string.format("  🏭  %-14s  %-10s  %.0f XP/tick", profile.displayName, tierStr, profile.xpPerTick)
				)

				local any = false
				for si = 1, profile.slotCount do
					local slot = machine.slots[si]
					if slot then
						any = true
						local can = canRepo:GetCan(PLAYER, slot.canId)
						local prog = can:GetProgress()
						print(
							string.format(
								"    [%d] %-8s  Lv.%-3d  %-12s  %s  %s  %.1f%%",
								si,
								slot.canId,
								can.level,
								WateringCanData.GetTierName(can.level),
								Bar(prog),
								can:GetProgressString(),
								prog * 100
							)
						)
					end
				end
				if not any then
					print("       (no cans slotted)")
				end
				print("")
			end
		end

		task.wait(config.tickInterval)
	end

	-- Final summary
	print(Sep("═"))
	print("  SIMULATION COMPLETE — Final Can States")
	print(Sep("═"))
	for _, canId in ipairs(canIds) do
		local can = canRepo:GetCan(PLAYER, canId)
		print(
			string.format(
				"  %-10s  Lv.%-3d  %-14s  %s  (in: %s)",
				canId,
				can.level,
				WateringCanData.GetTierName(can.level),
				can:GetProgressString(),
				tostring(can.inMachine)
			)
		)
	end
	print(Sep("═"))
	print("  [RbxMachineService] Simulation complete.")
	print("")
end

return RbxMachineService
