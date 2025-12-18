--!strict
-- Domain/Weapon.luau
-- Pure logic for a weapon's state and behavior.

local Weapon = {}
Weapon.__index = Weapon

export type WeaponState = {
	IsEquipped: boolean,
	IsAttacking: boolean,
	LastAttackTime: number,
}

export type WeaponImpl = {
	State: WeaponState,
	CanAttack: (self: WeaponImpl, currentTime: number, cooldown: number) -> boolean,
	StartAttack: (self: WeaponImpl, currentTime: number) -> (),
	StopAttack: (self: WeaponImpl) -> (),
}

function Weapon.new(): WeaponImpl
	local self = setmetatable({}, Weapon)
	self.State = {
		IsEquipped = false,
		IsAttacking = false,
		LastAttackTime = 0,
	}
	return (self :: any) :: WeaponImpl
end

function Weapon:CanAttack(currentTime: number, cooldown: number): boolean
	if not self.State.IsEquipped then
		return false
	end
	if self.State.IsAttacking then
		return false
	end
	return (currentTime - self.State.LastAttackTime) >= cooldown
end

function Weapon:StartAttack(currentTime: number)
	self.State.IsAttacking = true
	self.State.LastAttackTime = currentTime
end

function Weapon:StopAttack()
	self.State.IsAttacking = false
end

return Weapon
