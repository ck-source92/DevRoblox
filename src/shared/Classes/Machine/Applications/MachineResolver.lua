--[[
    MachineResolver  (Machine/Application)
    ────────────────────────────────────────
    Application service. Assembles the full runtime profile of a machine
    (config + tier + derived stats) from the registries and XPCalculator.

    Use cases call Resolve() to get everything they need in one call
    without reaching into registries directly.

    Profile shape:
    {
        machineType  : string
        config       : table    raw config from MachineData
        tier         : table?   upgrade tier (nil if level 0)
        upgradeLevel : number
        maxUpgrade   : number
        xpPerTick    : number   effective XP per tick
        slotCount    : number   effective slot count
        displayName  : string
    }
--]]

local RS = game:GetService("ReplicatedStorage")

local MachineRegistry = require(script.Parent.Parent.Infrastructure.MachineRegistry)
local UpgradeRegistry = require(script.Parent.Parent.Infrastructure.UpgradeRegistry)
local XPCalculator = require(RS.Shared.Classes.Machine.Domain.XpCalculator)

local MachineResolver = {}
MachineResolver.__index = MachineResolver

function MachineResolver.new()
	return setmetatable({}, MachineResolver)
end

--- Resolves the full profile for a machine type at a given upgrade level.
function MachineResolver:Resolve(machineType: string, upgradeLevel: number): table
	local config = MachineRegistry.Get(machineType)
	local tier = upgradeLevel > 0 and UpgradeRegistry.GetTier(config.upgradePath, upgradeLevel) or nil

	return {
		machineType = machineType,
		config = config,
		tier = tier,
		upgradeLevel = upgradeLevel,
		maxUpgrade = UpgradeRegistry.GetMaxLevel(config.upgradePath),
		xpPerTick = XPCalculator.GetXpPerTick(config, tier),
		slotCount = XPCalculator.GetSlotCount(config, tier),
		displayName = config.displayName,
	}
end

--- Returns the cost to upgrade to the next tier, or nil if already maxed.
function MachineResolver:GetNextUpgradeCost(machineType: string, currentLevel: number): number?
	local config = MachineRegistry.Get(machineType)
	local maxUpgrade = UpgradeRegistry.GetMaxLevel(config.upgradePath)
	if currentLevel >= maxUpgrade then
		return nil
	end

	local nextTier = UpgradeRegistry.GetTier(config.upgradePath, currentLevel + 1)
	return nextTier and nextTier.cost
end

-- Module-level singleton for convenience
local _instance = MachineResolver.new()

return _instance
