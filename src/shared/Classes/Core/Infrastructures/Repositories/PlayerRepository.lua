local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerRepository = {}
PlayerRepository.__index = PlayerRepository

function PlayerRepository.new(dataStoreService)
	local self = setmetatable({}, PlayerRepository)

	self.DataStoreService = dataStoreService
	self._cache = {}

	return self
end

function PlayerRepository:GetByID(id: number)
	if self._cache[id] then
		return self._cache[id]
	end

	-- Load from data store
	local data = self.DataStoreService:GetAsync("Player_" .. tostring(id))
	if not data then
		return nil
	end

	-- Convert to entity
	local PlayerEntity = require(ReplicatedStorage.Shared.Classes.Core.Domain.Entities.PlayerEntity)
	local player = PlayerEntity.new(data.id, data.username)
	player.Health = data.Health
	player.Level = data.Level

	self._cache[id] = player

	return player
end

function PlayerRepository:Save(player)
	local data = {
		Id = player.Id,
		Username = player.Username,
		Health = player.Health,
		Level = player.Level,
	}

	-- Save to data store
	self.DataStoreService:SetAsync("player_" .. tostring(player.Id), data)

	-- Update cache
	self._cache[player.Id] = player

	return true
end

function PlayerRepository:Exists(id: number)
	return self:GetByID(id) ~= nil
end

return PlayerRepository
