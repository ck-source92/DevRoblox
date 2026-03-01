--[[
    MachineRegistry  (Machine/Infrastructure)
    ──────────────────────────────────────────
    Loads, validates, and exposes machine type configs from MachineData.
    To add a machine: edit MachineData.Machines. Nothing else changes.
--]]

local RS = game:GetService("ReplicatedStorage")
local MachineData = require(RS.Shared.Data.MachineData)

-- Validate every entry at startup
for name, config in pairs(MachineData.Machines) do
	assert(type(config.displayName) == "string", "[MachineRegistry] " .. name .. ": missing displayName")
	assert(type(config.baseXpPerTick) == "number", "[MachineRegistry] " .. name .. ": missing baseXpPerTick")
	assert(type(config.maxCanSlots) == "number", "[MachineRegistry] " .. name .. ": missing maxCanSlots")
	assert(type(config.upgradePath) == "string", "[MachineRegistry] " .. name .. ": missing upgradePath")
	assert(
		MachineData.UpgradePaths[config.upgradePath],
		"[MachineRegistry] " .. name .. ": unknown upgradePath '" .. config.upgradePath .. "'"
	)
end

local MachineRegistry = {}

function MachineRegistry.Get(machineType: string): table
	local config = MachineData.Machines[machineType]
	assert(config, "[MachineRegistry] Unknown machine type: " .. tostring(machineType))
	return config
end

function MachineRegistry.Has(machineType: string): boolean
	return MachineData.Machines[machineType] ~= nil
end

function MachineRegistry.GetAll(): { [string]: table }
	return MachineData.Machines
end

return MachineRegistry
