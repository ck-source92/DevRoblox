--[[
    PickupCanUseCase  (WateringCan/Application)
    ─────────────────────────────────────────────
    Called when a player presses E on a watering can ProximityPrompt.

    Responsibilities:
      • Validate the can exists in the given machine slot
      • Remove it from the slot (delegates to RemoveCanUseCase)
      • Mark the can as "carried" on the entity (inMachine = nil)

    Returns:
    {
        success  : boolean
        message  : string
        can      : WateringCanEntity?   the picked-up can (nil on failure)
        canId    : string?
        slotIndex: number?
    }

    The caller (MachineService) is responsible for:
      • Giving the player a Tool representing this can
      • Triggering AutoRefillUseCase to fill the empty slot
      • Updating CanWorldManager to remove the world Part
--]]
local RS = game:GetService("ReplicatedStorage")
local RemoveCanUseCase = require(RS.Shared.Classes.Machine.Applications.RemoveCanUsecase)

local PickUpCanUseCase = {}
PickUpCanUseCase.__index = PickUpCanUseCase

---@param machineRepo  IMachineRepository
---@param canRepo      IWateringCanRepository
function PickUpCanUseCase.new(machineRepo: table, canRepo: table)
	assert(machineRepo, "PickupCanUseCase: machineRepo required")
	assert(canRepo, "PickupCanUseCase: canRepo required")
	return setmetatable({
		_machines = machineRepo,
		_cans = canRepo,
		_removeUC = RemoveCanUseCase.new(machineRepo, canRepo),
	}, PickUpCanUseCase)
end

---@param player     any
---@param machineId  string
---@param slotIndex  number
function PickUpCanUseCase:Execute(player: any, machineId: string, slotIndex: number): table
	local machine = self._machines:GetMachine(machineId)
	if not machine then
		return { success = false, message = "Machine not found." }
	end

	local slot = machine.slots[slotIndex]
	if not slot then
		return { success = false, message = "Slot is empty." }
	end

	-- Only the owner of the can can pick it up
	if slot.player ~= player then
		return { success = false, message = "This is not your watering can." }
	end

	local canId = slot.canId
	local result = self._removeUC:Execute(player, machineId, canId)

	if not result.success then
		return { success = false, message = result.message }
	end

	local can = self._cans:GetCan(player, canId)

	return {
		success = true,
		message = "Picked up " .. canId .. " from slot " .. slotIndex .. ".",
		can = can,
		canId = canId,
		slotIndex = slotIndex,
	}
end

return PickUpCanUseCase
