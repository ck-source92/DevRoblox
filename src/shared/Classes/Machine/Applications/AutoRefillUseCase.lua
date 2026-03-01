--[[
    AutoRefillUseCase  (Machine/Application)
    ──────────────────────────────────────────
    Automatically refills an empty machine slot with a brand-new watering can
    immediately after a player picks one up.

    Flow:
        Player picks up can
            → PickupCanUseCase empties the slot
            → AutoRefillUseCase fires
            → new can is created for that player
            → new can is inserted into the same slot
            → CanWorldManager spawns a fresh world Part
            → machine keeps filling without interruption

    Returns:
    {
        success    : boolean
        message    : string
        newCanId   : string?    id of the freshly created can
        slotIndex  : number?
    }
--]]

local RS = game:GetService("ReplicatedStorage")
local InsertCanUseCase = require(RS.Shared.Classes.Machine.Applications.InsertCanUseCase)
local CreateCanUseCase = require(RS.Shared.Classes.WaterCan.Applications.CreateCanUseCase)

local AutoRefillUseCase = {}
AutoRefillUseCase.__index = AutoRefillUseCase

---@param machineRepo   IMachineRepository
---@param canRepo       IWateringCanRepository
function AutoRefillUseCase.new(machineRepo: table, canRepo: table)
	assert(machineRepo, "AutoRefillUseCase: machineRepo required")
	assert(canRepo, "AutoRefillUseCase: canRepo required")

	return setmetatable({
		_machines = machineRepo,
		_cans = canRepo,
		_createUC = CreateCanUseCase.new(canRepo),
		_insertUC = InsertCanUseCase.new(machineRepo, canRepo),
	}, AutoRefillUseCase)
end

---@param player     any     player who owns the machine / whose slot to refill
---@param machineId  string
---@param slotIndex  number  the slot that just became empty
function AutoRefillUseCase:Execute(player: any, machineId: string, slotIndex: number): table
	local machine = self._machines:GetMachine(machineId)
	if not machine then
		return { success = false, message = "Machine not found." }
	end

	if machine.slots[slotIndex] then
		return { success = false, message = "Slot " .. slotIndex .. " is not empty." }
	end

	-- Create a fresh level-1 can
	local newCan = self._createUC:Execute(player)
	if not newCan then
		return { success = false, message = "Failed to create new can." }
	end

	-- Insert it into the now-empty slot
	local insertResult = self._insertUC:Execute(player, machineId, newCan.canId)
	if not insertResult.success then
		return { success = false, message = "Auto-refill insert failed: " .. insertResult.message }
	end

	return {
		success = true,
		message = "Slot " .. slotIndex .. " refilled with " .. newCan.canId,
		newCanId = newCan.canId,
		slotIndex = slotIndex,
	}
end

return AutoRefillUseCase
