local XPCalculator = {}

--- Returns effective XP per tick.
--- @param config  table   machine config (baseXpPerTick)
--- @param tier    table?  upgrade tier (xpMultiplier, future keys)
function XPCalculator.GetXpPerTick(config: table, tier: table?): number
	local xp = config.baseXpPerTick

	if tier then
		if type(tier.xpMultiplier) == "number" then
			xp = xp * tier.xpMultiplier
		end
		-- Future: flat bonus on top of multiplied XP
		-- if type(tier.bonusXp) == "number" then xp = xp + tier.bonusXp end
	end

	return xp
end

--- Returns effective slot count.
--- @param config  table   machine config (maxCanSlots)
--- @param tier    table?  upgrade tier (slotBonus)
function XPCalculator.GetSlotCount(config: table, tier: table?): number
	local slots = config.maxCanSlots

	if tier then
		if type(tier.slotBonus) == "number" then
			slots = slots + tier.slotBonus
		end
	end

	return slots
end

return XPCalculator
