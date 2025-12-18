--!strict
-- Domain/Wallet.luau
-- Pure business logic for managing a point balance.

local Wallet = {}
Wallet.__index = Wallet

export type WalletImpl = {
	_balance: number,
	Add: (self: WalletImpl, amount: number) -> number,
	Remove: (self: WalletImpl, amount: number) -> boolean,
	Get: (self: WalletImpl) -> number,
}

function Wallet.new(initialBalance: number?): WalletImpl
	local self = setmetatable({}, Wallet)
	self._balance = math.max(0, initialBalance or 0)
	return (self :: any) :: WalletImpl
end

function Wallet:Add(amount: number): number
	if amount <= 0 then
		-- In domain logic, adding negative or zero might be invalid or no-op.
		-- We'll allow 0 but ignore negative (use Remove for that).
		return self._balance
	end
	self._balance += amount
	return self._balance
end

function Wallet:Remove(amount: number): boolean
	if amount <= 0 then
		return false
	end
	if self._balance >= amount then
		self._balance -= amount
		return true
	end
	return false
end

function Wallet:Get(): number
	return self._balance
end

return Wallet
