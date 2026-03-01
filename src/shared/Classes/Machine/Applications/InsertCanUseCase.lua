--[[
    InsertCanUseCase  (Machine/Application)
    ─────────────────────────────────────────
    Inserts a player's watering can into the first available machine slot.

    Result: { success: boolean, message: string, slotIndex: number? }
--]]

local MachineResolver = require(script.Parent.MachineResolver)

local InsertCanUseCase = {}
InsertCanUseCase.__index = InsertCanUseCase

---@param machineRepo  IMachineRepository
---@param canRepo      IWateringCanRepository
function InsertCanUseCase.new(machineRepo: table, canRepo: table)
	return setmetatable({ _machines = machineRepo, _cans = canRepo }, InsertCanUseCase)
end

function InsertCanUseCase:Execute(player: any, machineId: string, canId: string): table
	local machine = self._machines:GetMachine(machineId)
	if not machine then
		return { success = false, message = "Machine not found." }
	end

	local can = self._cans:GetCan(player, canId)
	if not can then
		return { success = false, message = "Watering can not found." }
	end
	if can:IsInMachine() then
		return { success = false, message = "Can is already inside a machine." }
	end

	local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
	local slotIndex = machine:FindFreeSlot(profile.slotCount)

	if not slotIndex then
		return { success = false, message = "Machine is full." }
	end

	-- Mutate both entities
	machine:InsertCan(slotIndex, player, canId)
	can:SetMachine(machineId)

	-- Persist
	self._cans:SaveCan(player, can)

	return { success = true, message = "Inserted into slot " .. slotIndex .. ".", slotIndex = slotIndex }
end

return InsertCanUseCase
