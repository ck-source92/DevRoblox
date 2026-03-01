--[[
    WateringCanData
    ────────────────
    All watering can progression data in one place.

    To add more levels → extend LevelTable (formula auto-scales beyond it)
    To add tier names  → extend TierNames
--]]

local WateringCanData = {}

-- XP needed to go from level N → N+1
WateringCanData.LevelTable = {
	[1] = 100,
	[2] = 1_000,
	[3] = 5_000,
	[4] = 15_000,
	[5] = 40_000,
	[6] = 100_000,
	[7] = 250_000,
	[8] = 600_000,
	[9] = 1_400_000,
	[10] = 3_000_000,
}

WateringCanData.TierNames = {
	[1] = "Wooden Can",
	[2] = "Iron Can",
	[3] = "Bronze Can",
	[4] = "Silver Can",
	[5] = "Golden Can",
	[6] = "Sapphire Can",
	[7] = "Ruby Can",
	[8] = "Emerald Can",
	[9] = "Diamond Can",
	[10] = "Mythic Can",
}

WateringCanData.DefaultTierPattern = "Crystal Can Lv.%d"

function WateringCanData.GetTierName(level: number): string
	return WateringCanData.TierNames[level] or WateringCanData.DefaultTierPattern:format(level)
end

return WateringCanData
