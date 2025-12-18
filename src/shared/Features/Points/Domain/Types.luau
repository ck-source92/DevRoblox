--!strict

export type Wallet = {
	Balance: number,
	Add: (self: Wallet, amount: number) -> number,
	Remove: (self: Wallet, amount: number) -> boolean,
	Get: (self: Wallet) -> number,
}

export type CoinType = {
	Value: number,
	Type: "Gold" | "Silver" | "Bronze",
}

return nil
