--!strict
-- Domain/Coin.luau
-- Defines a Coin entity.

local Types = require(script.Parent.Types)

local Coin = {}
Coin.__index = Coin

export type CoinImpl = {
	Value: number,
	Type: string,
}

function Coin.new(value: number, coinType: string?): CoinImpl
	local self = setmetatable({}, Coin)
	self.Value = value
	self.Type = coinType or "Gold"
	return (self :: any) :: CoinImpl
end

return Coin
