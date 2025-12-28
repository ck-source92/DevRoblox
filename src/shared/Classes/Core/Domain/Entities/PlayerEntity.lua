local PlayerEntity = {}
PlayerEntity.__index = PlayerEntity

function PlayerEntity.new(id: number, username: string)
	local self = setmetatable({}, PlayerEntity)

	self.Id = id
	self.Username = username
	self.Health = 100
	self.MaxHealth = 200
	self.Level = 1

	return self
end

function PlayerEntity:TakeDamage(amount: number)
	self.Health = math.max(0, self.Health - amount)
	return self.Health <= 0
end

function PlayerEntity:Heal(amount: number)
	self.Health = math.min(self.MaxHealth, self.Health + amount)
end

return PlayerEntity
