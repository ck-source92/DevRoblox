--[[
    RbxWateringCanService  (ModuleScript)
    ──────────────────────────────────────
    Standalone WateringCan domain simulation module.
    No Knit, no Players required.

    Usage:
        local Sim = require(path.RbxWateringCanService)
        Sim.Run()                              -- default config
        Sim.Run({ totalTicks = 20 })           -- custom config

    Config options (all optional):
        totalTicks    number    How many ticks to simulate       (default 40)
        tickInterval  number    Seconds between ticks            (default 1)
        printEvery    number    Print status every N ticks       (default 5)
        xpPerCan      table     { [canIndex] = xp }             (default below)
        debugMode     boolean   Print every single XP event      (default false)
--]]

local RS = game:GetService("ReplicatedStorage")

local WateringCanRepository = require(RS.Shared.Classes.WaterCan.Infrasturcture.WaterCanRepository)
local CreateCanUseCase = require(RS.Shared.Classes.WaterCan.Applications.CreateCanUseCase)
local AddXPUseCase = require(RS.Shared.Classes.WaterCan.Applications.AddXPUseCase)
local WateringCanData = require(RS.Shared.Data.WateringCanData)

-- ── Defaults ──────────────────────────────────────────────────────────────────

local DEFAULTS = {
	totalTicks = 40,
	tickInterval = 1,
	printEvery = 5,
	debugMode = false,
	xpPerCan = {
		[1] = 5, -- mimics HandPump   base
		[2] = 12, -- mimics WaterWheel base
		[3] = 30, -- mimics SteamFiller base
	},
}

-- ── Render helpers ────────────────────────────────────────────────────────────

local BAR_WIDTH = 24
local function Bar(p)
	local f = math.floor(p * BAR_WIDTH)
	return "[" .. string.rep("█", f) .. string.rep("░", BAR_WIDTH - f) .. "]"
end
local function Sep(c, n)
	return string.rep(c or "─", n or 62)
end

local function LevelUpBanner(canId, level)
	print("")
	print(
		"  ╔══════════════════════════════════════════╗"
	)
	print(string.format("  ║  🌟  LEVEL UP!  %-26s║", ""))
	print(string.format("  ║  %-8s  →  Lv.%-3d  %-20s║", canId, level, WateringCanData.GetTierName(level)))
	print(
		"  ╚══════════════════════════════════════════╝"
	)
	print("")
end

-- ── Module ────────────────────────────────────────────────────────────────────

local RbxWaterCanService = {}

function RbxWaterCanService.Run(cfg)
	local config = {}
	for k, v in pairs(DEFAULTS) do
		config[k] = v
	end
	if cfg then
		for k, v in pairs(cfg) do
			config[k] = v
		end
	end

	-- Wire domain
	local repo = WateringCanRepository.new()
	local createUC = CreateCanUseCase.new(repo)
	local addXPUC = AddXPUseCase.new(repo)

	local PLAYER = { Name = "SimPlayer", UserId = 0 }
	repo:InitPlayer(PLAYER)

	local canIds = {}
	for i = 1, 3 do
		local can = createUC:Execute(PLAYER)
		if i == 2 then -- head-start on can 2 for early level-up
			can:ApplyXP(80)
			repo:SaveCan(PLAYER, can)
		end
		table.insert(canIds, can.canId)
	end

	-- Header
	print(Sep("═"))
	print("  [RbxWateringCanService]  WATERING CAN SIMULATION")
	print(
		string.format(
			"  Ticks: %d  ·  Interval: %ds  ·  Cans: %d  ·  Debug: %s",
			config.totalTicks,
			config.tickInterval,
			#canIds,
			tostring(config.debugMode)
		)
	)
	print(Sep("═"))

	for tick = 1, config.totalTicks do
		for i, canId in ipairs(canIds) do
			local xp = config.xpPerCan[i] or 5
			local result = addXPUC:Execute(PLAYER, canId, xp)

			if result then
				if config.debugMode then
					print(
						string.format(
							"  [DEBUG] tick=%-3d  can=%-8s  +%4d XP  lvl=%-3d  xp=%d",
							tick,
							canId,
							xp,
							result.newLevel,
							result.newXP
						)
					)
				end
				if result.levelUps > 0 then
					LevelUpBanner(canId, result.newLevel)
				end
			end
		end

		if tick % config.printEvery == 0 or tick == 1 or tick == config.totalTicks then
			print(Sep("─"))
			print(string.format("  Tick %3d / %d", tick, config.totalTicks))
			print(Sep("─"))
			for i, canId in ipairs(canIds) do
				local can = repo:GetCan(PLAYER, canId)
				local prog = can:GetProgress()
				print(
					string.format(
						"  %-8s  Lv.%-3d  %-14s  %s  %s  +%d/tick",
						canId,
						can.level,
						WateringCanData.GetTierName(can.level),
						Bar(prog),
						can:GetProgressString(),
						config.xpPerCan[i] or 5
					)
				)
			end
			print("")
		end

		task.wait(config.tickInterval)
	end

	print(Sep("═"))
	print("  FINAL STATE")
	print(Sep("═"))
	for _, canId in ipairs(canIds) do
		local can = repo:GetCan(PLAYER, canId)
		print(
			string.format(
				"  %-8s  Lv.%-3d  %-14s  %s",
				canId,
				can.level,
				WateringCanData.GetTierName(can.level),
				can:GetProgressString()
			)
		)
	end
	print(Sep("═"))
	print("  [RbxWateringCanService] Simulation complete.")
	print("")
end

return RbxWaterCanService
