--[[
    WaterCanRepository  (WaterCan/Infrastructure)
    ─────────────────────────────────────────────────
    In-memory implementation of IWaterCanRepository.

    Swap this out for a DataStore-backed version later without changing
    any use case or service code — just inject the new repo.

    Storage shape:
        _store[player][canId] = WaterCanEntity
--]]

local RS = game:GetService("ReplicatedStorage")

local WaterCanEntity = require(script.Parent.Parent.Domain.WaterCanEntity)
local IWaterCanRepository = require(script.Parent.Parent.Interfaces.IWaterCanRepository)
local LevelUtil = require(RS.Shared.Modules.LevelUtil)
local WateringCanData = require(RS.Shared.Data.WateringCanData)

local WaterCanRepository = {}
WaterCanRepository.__index = WaterCanRepository

function WaterCanRepository.new()
	local self = setmetatable({ _store = {} }, WaterCanRepository)
	IWaterCanRepository.Validate(self, "WaterCanRepository")
	return self
end

function WaterCanRepository:InitPlayer(player: Player)
	if not self._store[player] then
		self._store[player] = {}
	end
end

function WaterCanRepository:RemovePlayer(player: Player)
	-- TODO: flush to DataStore before clearing
	self._store[player] = nil
end

function WaterCanRepository:HasPlayer(player: Player): boolean
	return self._store[player] ~= nil
end

function WaterCanRepository:GetCan(player: Player, canId: string): table?
	local inv = self._store[player]
	return inv and inv[canId]
end

function WaterCanRepository:SaveCan(player: Player, can: table)
	local inv = self._store[player]
	if inv then
		inv[can.canId] = can
	end
end

function WaterCanRepository:DeleteCan(player: Player, canId: string)
	local inv = self._store[player]
	if inv then
		inv[canId] = nil
	end
end

--- Returns all WaterCanEntities for a player as a { [canId]: entity } table.
function WaterCanRepository:GetInventory(player: Player): { [string]: table }
	return self._store[player] or {}
end

--- Returns a serialized snapshot of all cans (plain tables, safe for replication).
function WaterCanRepository:GetInventorySnapshot(player: Player): { [string]: table }
	local inv = self._store[player] or {}
	local snapshot = {}
	for canId, can in pairs(inv) do
		snapshot[canId] = can:Serialize()
	end
	return snapshot
end

--- Loads persisted data back into entities (call after DataStore fetch).
function WaterCanRepository:LoadInventory(player: Player, data: { [string]: table })
	self:InitPlayer(player)
	for canId, raw in pairs(data) do
		local can = WaterCanEntity.Deserialize(raw, LevelUtil, WateringCanData.LevelTable)
		self._store[player][canId] = can
	end
end

return WaterCanRepository
