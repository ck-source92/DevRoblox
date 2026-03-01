--[[
    MachineTickUseCase  (Machine/Application)
    ───────────────────────────────────────────
    Called every second (tick interval). Iterates all registered machines,
    computes effective XP per tick, and delegates to AddXPUseCase for each
    slotted watering can.

    Returns a list of tick results so callers (Knit service, simulation)
    can fire signals, update UI, or log events without this use case
    knowing anything about networking or Roblox instances.

    TickResult shape:
    {
        machineId  : string
        slotIndex  : number
        player     : any
        canId      : string
        xpApplied  : number
        levelUps   : number
        newLevel   : number
        newXP      : number
    }
--]]

local MachineResolver = require(script.Parent.MachineResolver)

local MachineTickUseCase = {}
MachineTickUseCase.__index = MachineTickUseCase

---@param machineRepo  IMachineRepository
---@param addXPUseCase AddXPUseCase
function MachineTickUseCase.new(machineRepo: table, addXPUseCase: table)
	assert(machineRepo, "MachineTickUseCase: machineRepo is required")
	assert(addXPUseCase, "MachineTickUseCase: addXPUseCase is required")
	return setmetatable({
		_machines = machineRepo,
		_addXP = addXPUseCase,
	}, MachineTickUseCase)
end

--- Runs one tick. Returns array of TickResult tables.
function MachineTickUseCase:Execute(): { table }
	local results = {}
	local machines = self._machines:GetAllMachines()

	for machineId, machine in pairs(machines) do
		local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
		local xpPerTick = profile.xpPerTick

		for slotIndex = 1, profile.slotCount do
			local slot = machine.slots[slotIndex]
			if slot then
				local result = self._addXP:Execute(slot.player, slot.canId, xpPerTick)

				if result then
					table.insert(results, {
						machineId = machineId,
						slotIndex = slotIndex,
						player = slot.player,
						canId = slot.canId,
						xpApplied = xpPerTick,
						levelUps = result.levelUps,
						newLevel = result.newLevel,
						newXP = result.newXP,
					})
				else
					-- Can was removed from inventory while still slotted — clean up
					machine:RemoveSlot(slotIndex)
				end
			end
		end
	end

	return results
end

return MachineTickUseCase
