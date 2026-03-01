local MachineEntity = {}
MachineEntity.__index = MachineEntity

---@param machineId    string
---@param machineType  string   must match a key in MachineData.Machines
---@param upgradeLevel number   0 = base
function MachineEntity.new(machineId: string, machineType: string, upgradeLevel: number?)
	assert(type(machineId) == "string", "MachineEntity: machineId must be a string")
	assert(type(machineType) == "string", "MachineEntity: machineType must be a string")

	return setmetatable({
		machineId = machineId,
		machineType = machineType,
		upgradeLevel = upgradeLevel or 0,
		-- slots[index] = { player: Player, canId: string } | nil
		slots = {},
	}, MachineEntity)
end

--- Returns the first empty slot index within `maxSlots`, or nil if full.
function MachineEntity:FindFreeSlot(maxSlots: number): number?
	for i = 1, maxSlots do
		if not self.slots[i] then
			return i
		end
	end
	return nil
end

--- Returns the slot index of a specific can, or nil if not found.
function MachineEntity:FindCanSlot(player: any, canId: string): number?
	for i, slot in pairs(self.slots) do
		if slot.player == player and slot.canId == canId then
			return i
		end
	end
	return nil
end

--- Inserts a can into a given slot. Caller must validate the slot is free.
function MachineEntity:InsertCan(slotIndex: number, player: any, canId: string)
	self.slots[slotIndex] = { player = player, canId = canId }
end

--- Removes the can at a given slot.
function MachineEntity:RemoveSlot(slotIndex: number)
	self.slots[slotIndex] = nil
end

--- Returns how many slots are currently occupied.
function MachineEntity:GetOccupiedSlotCount(): number
	local count = 0
	for _ in pairs(self.slots) do
		count = count + 1
	end
	return count
end

--- Advances the upgrade level by 1.
function MachineEntity:Upgrade()
	self.upgradeLevel = self.upgradeLevel + 1
end

function MachineEntity:Serialize(): table
	local slotsData = {}
	for i, slot in pairs(self.slots) do
		slotsData[i] = { player = slot.player, canId = slot.canId }
	end
	return {
		machineId = self.machineId,
		machineType = self.machineType,
		upgradeLevel = self.upgradeLevel,
		slots = slotsData,
	}
end

function MachineEntity.Deserialize(data: table)
	local entity = MachineEntity.new(data.machineId, data.machineType, data.upgradeLevel)
	entity.slots = data.slots or {}
	return entity
end

return MachineEntity
