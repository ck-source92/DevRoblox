--[[
    MachineData
    ────────────
    All machine types and upgrade paths in one place.

    To add a machine  → add to Machines{}
    To add a path     → add to UpgradePaths{}
    To add new upgrade effect → add a key to tier (e.g. slotBonus), read it in XPCalculator
--]]

local MachineData = {}

MachineData.UpgradePaths = {
	BasicPath = {
		{ cost = 500, xpMultiplier = 1.5 },
		{ cost = 2_000, xpMultiplier = 2.5 },
		{ cost = 8_000, xpMultiplier = 4.0 },
		{ cost = 25_000, xpMultiplier = 7.0 },
	},

	AdvancedPath = {
		{ cost = 2_000, xpMultiplier = 2.0 },
		{ cost = 10_000, xpMultiplier = 4.0 },
		{ cost = 40_000, xpMultiplier = 8.0 },
		{ cost = 150_000, xpMultiplier = 15.0 },
	},

	IndustrialPath = {
		{ cost = 10_000, xpMultiplier = 3.0 },
		{ cost = 50_000, xpMultiplier = 7.0 },
		{ cost = 200_000, xpMultiplier = 15.0 },
		{ cost = 800_000, xpMultiplier = 30.0 },
	},
}

MachineData.Machines = {
	HandPump = {
		displayName = "Hand Pump",
		baseXpPerTick = 5,
		maxCanSlots = 1,
		upgradePath = "BasicPath",
	},

	WaterWheel = {
		displayName = "Water Wheel",
		baseXpPerTick = 12,
		maxCanSlots = 2,
		upgradePath = "BasicPath",
	},

	SteamFiller = {
		displayName = "Steam Filler",
		baseXpPerTick = 30,
		maxCanSlots = 3,
		upgradePath = "AdvancedPath",
	},

	HydroPress = {
		displayName = "Hydro Press",
		baseXpPerTick = 75,
		maxCanSlots = 4,
		upgradePath = "AdvancedPath",
	},

	NanoFiller = {
		displayName = "Nano Filler",
		baseXpPerTick = 200,
		maxCanSlots = 6,
		upgradePath = "IndustrialPath",
	},

	QuantumPump = {
		displayName = "Quantum Pump",
		baseXpPerTick = 500,
		maxCanSlots = 8,
		upgradePath = "IndustrialPath",
	},
}

return MachineData
