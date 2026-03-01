--[[
    WaterCanEntity  (WaterCan/Domain)
    ────────────────────────────────────────
    The core domain entity. Holds state and owns all business rules
    for a single watering can.

    Pure Lua — no Roblox, no Knit, no data requires.
    LevelUtil and WaterCanData are injected via the constructor
    so this entity is testable in isolation.
--]]

local WaterCanEntity = {}
WaterCanEntity.__index = WaterCanEntity

-- ── Constructor ───────────────────────────────────────────────────────────────

---@param canId        string
---@param levelUtil    table   LevelUtil module (injected)
---@param levelTable   table   { [number]: number } XP thresholds (injected)
---@param overrides    table?  { level, currentXP, inMachine }
function WaterCanEntity.new(canId: string, levelUtil: table, levelTable: table, overrides: table?)
	assert(type(canId) == "string", "WaterCanEntity: canId must be a string")
	assert(levelUtil, "WaterCanEntity: levelUtil is required")
	assert(levelTable, "WaterCanEntity: levelTable is required")

	local self = setmetatable({}, WaterCanEntity)

	-- Core state
	self.canId = canId
	self.level = (overrides and overrides.level) or 1
	self.currentXP = (overrides and overrides.currentXP) or 0
	self.inMachine = (overrides and overrides.inMachine) or nil

	-- Injected dependencies (private)
	self._levelUtil = levelUtil
	self._levelTable = levelTable

	return self
end

-- ── Business Logic ────────────────────────────────────────────────────────────

--- Applies XP to this can. Handles level-ups internally.
--- Returns { levelUps: number, newLevel: number, newXP: number }
function WaterCanEntity:ApplyXP(amount: number): table
	local newLevel, newXP, levelUps = self._levelUtil.AddXP(self._levelTable, self.level, self.currentXP, amount)
	self.level = newLevel
	self.currentXP = newXP
	return { levelUps = levelUps, newLevel = newLevel, newXP = newXP }
end

--- Returns 0–1 fill progress for this can's current level.
function WaterCanEntity:GetProgress(): number
	return self._levelUtil.GetProgress(self._levelTable, self.level, self.currentXP)
end

--- Returns a formatted XP string e.g. "250 / 1,000 XP"
function WaterCanEntity:GetProgressString(): string
	return self._levelUtil.GetProgressString(self._levelTable, self.level, self.currentXP)
end

--- Returns XP required for the next level-up.
function WaterCanEntity:GetRequiredXP(): number
	return self._levelUtil.GetRequiredXP(self._levelTable, self.level)
end

--- Assigns or clears the machine this can is inside.
function WaterCanEntity:SetMachine(machineId: string?)
	self.inMachine = machineId
end

--- Returns true if this can is currently being filled by a machine.
function WaterCanEntity:IsInMachine(): boolean
	return self.inMachine ~= nil
end

--- Returns a plain table safe for DataStore or replication.
function WaterCanEntity:Serialize(): table
	return {
		canId = self.canId,
		level = self.level,
		currentXP = self.currentXP,
		inMachine = self.inMachine,
	}
end

--- Reconstructs an entity from a serialized table.
function WaterCanEntity.Deserialize(data: table, levelUtil: table, levelTable: table)
	return WaterCanEntity.new(data.canId, levelUtil, levelTable, {
		level = data.level,
		currentXP = data.currentXP,
		inMachine = data.inMachine,
	})
end

return WaterCanEntity
