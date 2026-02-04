local PlayerDTO = {}
PlayerDTO.__index = PlayerDTO

function PlayerDTO.FromEntity(playerEntity)
	return {
		Id = playerEntity.Id,
		Username = playerEntity.Username,
		Health = playerEntity.Health,
		MaxHealth = playerEntity.MaxHealth,
		Level = playerEntity.Level,
		IsAlive = playerEntity.Health > 0,
	}
end

function PlayerDTO.ToEntity(playerDto)
	local PlayerEntity = require(script.Parent.Parent.Parent.Domain.Entities.PlayerEntity)
	local player = PlayerEntity.new(playerDto.Id, playerDto.Username)
	player.Health = playerDto.Health
	player.Level = playerDto.Level
	return player
end

return PlayerDTO
