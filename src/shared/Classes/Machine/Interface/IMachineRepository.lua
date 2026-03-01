--[[
    IMachineRepository  (Machine/Interfaces)
    ─────────────────────────────────────────
    Contract for any machine repository implementation.

    Methods:
        RegisterMachine(machine)        → void
        UnregisterMachine(machineId)    → void
        GetMachine(machineId)           → MachineEntity?
        GetAllMachines()                → { [machineId]: MachineEntity }
        HasMachine(machineId)           → boolean
--]]

local IMachineRepository = {}

function IMachineRepository.Validate(repo: table, label: string?)
	local lbl = label or "IMachineRepository"
	local required = { "RegisterMachine", "UnregisterMachine", "GetMachine", "GetAllMachines", "HasMachine" }
	for _, method in ipairs(required) do
		assert(type(repo[method]) == "function", string.format("%s: missing method '%s'", lbl, method))
	end
end

return IMachineRepository
