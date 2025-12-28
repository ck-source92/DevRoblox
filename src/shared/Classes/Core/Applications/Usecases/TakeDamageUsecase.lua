local TakeDamageUsecase = {}
TakeDamageUsecase.__index = TakeDamageUsecase

function TakeDamageUsecase.new(playerRepository, eventPublisher)
	local self = setmetatable({}, TakeDamageUsecase)

	self.PlayerRepository = playerRepository
	self.EventPublisher = eventPublisher

	return self
end

function TakeDamageUsecase:Execute(playerId: number, damage: number)
	local player = self.PlayerRepository:GetByID(playerId)

	if not player then
		return false, "Player not found"
	end

	if damage <= 0 then
		return false, "Damage can't be negative number"
	end

	if player.Health <= 0 then
		return false, "Player is defeated!"
	end

	local isDefeated = player:TakeDamage(damage)

	self.PlayerRepository:Save(player)

	self.EventPublisher:Publish("PlayerDamaged", {
		PlayerID = playerId,
		Damage = damage,
		RemainingHealth = player.Health,
		IsDefeated = isDefeated,
	})

	return true, "Damage Applied", {
		RemainingHealth = player.Health,
		IsDefeated = isDefeated,
	}
end

return TakeDamageUsecase
