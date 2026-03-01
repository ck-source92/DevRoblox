--[[
    UpgradeRegistry  (Machine/Infrastructure)
    ──────────────────────────────────────────
    Loads, validates, and exposes upgrade paths from MachineData.
    To add/change a path or tier: edit MachineData.UpgradePaths. Done.
--]]

local RS = game:GetService("ReplicatedStorage")
local MachineData = require(RS.Shared.Data.MachineData)

-- Validate every path and tier at startup
for pathName, tiers in pairs(MachineData.UpgradePaths) do
	assert(type(tiers) == "table" and #tiers > 0, "[UpgradeRegistry] " .. pathName .. ": must be a non-empty array")
	for i, tier in ipairs(tiers) do
		assert(type(tier.cost) == "number", string.format("[UpgradeRegistry] %s tier %d: missing 'cost'", pathName, i))
		assert(
			type(tier.xpMultiplier) == "number",
			string.format("[UpgradeRegistry] %s tier %d: missing 'xpMultiplier'", pathName, i)
		)
	end
end

local UpgradeRegistry = {}

--- Returns the tier table at upgradeLevel (1-based). Nil if out of range.
function UpgradeRegistry.GetTier(pathName: string, upgradeLevel: number): table?
	local path = MachineData.UpgradePaths[pathName]
	assert(path, "[UpgradeRegistry] Unknown path: " .. tostring(pathName))
	return path[upgradeLevel]
end

function UpgradeRegistry.GetMaxLevel(pathName: string): number
	local path = MachineData.UpgradePaths[pathName]
	assert(path, "[UpgradeRegistry] Unknown path: " .. tostring(pathName))
	return #path
end

function UpgradeRegistry.Has(pathName: string): boolean
	return MachineData.UpgradePaths[pathName] ~= nil
end

return UpgradeRegistry
