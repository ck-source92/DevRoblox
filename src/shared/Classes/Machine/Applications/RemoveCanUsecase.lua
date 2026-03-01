--[[
    RemoveCanUseCase  (Machine/Application)
    ─────────────────────────────────────────
    Removes a player's watering can from whichever slot it occupies.

    Result: { success: boolean, message: string, slotIndex: number? }
--]]

local RemoveCanUsecase = {}
RemoveCanUsecase.__index = RemoveCanUsecase

function RemoveCanUsecase.new(machineRepo: table, canRepo: table)
	return setmetatable({ _machines = machineRepo, _cans = canRepo }, RemoveCanUsecase)
end

function RemoveCanUsecase:Execute(player: any, machineId: string, canId: string): table
	local machine = self._machines:GetMachine(machineId)
	if not machine then
		return { success = false, message = "Machine not found." }
	end

	local slotIndex = machine:FindCanSlot(player, canId)
	if not slotIndex then
		return { success = false, message = "Can not found in this machine." }
	end

	local can = self._cans:GetCan(player, canId)

	-- Mutate both entities
	machine:RemoveSlot(slotIndex)
	if can then
		can:SetMachine(nil)
		self._cans:SaveCan(player, can)
	end

	return { success = true, message = "Removed from slot " .. slotIndex .. ".", slotIndex = slotIndex }
end

return RemoveCanUsecase
