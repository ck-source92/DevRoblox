--[[
    MachineRepository  (Machine/Infrastructure)
    ─────────────────────────────────────────────
    In-memory store of MachineEntity instances.
    Swap for a persistence-backed version without changing any use case.
--]]

local RS = game:GetService("ReplicatedStorage")
local IMachineRepository = require(RS.Shared.Classes.Machine.Interface.IMachineRepository)

local MachineRepository = {}
MachineRepository.__index = MachineRepository

function MachineRepository.new()
	local self = setmetatable({ _store = {} }, MachineRepository)
	IMachineRepository.Validate(self, "MachineRepository")
	return self
end

function MachineRepository:RegisterMachine(machine: table)
	self._store[machine.machineId] = machine
end

function MachineRepository:UnregisterMachine(machineId: string)
	self._store[machineId] = nil
end

function MachineRepository:GetMachine(machineId: string): table?
	return self._store[machineId]
end

function MachineRepository:GetAllMachines(): { [string]: table }
	return self._store
end

function MachineRepository:HasMachine(machineId: string): boolean
	return self._store[machineId] ~= nil
end

return MachineRepository
