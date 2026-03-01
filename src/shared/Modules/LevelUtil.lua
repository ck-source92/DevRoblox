--[[
    LevelUtil  (Shared/Modules)
    ────────────────────────────
    Pure XP math. No Roblox, no Knit, no data dependencies.
    Receives the levelTable as a parameter so it stays decoupled from data.
--]]

local LevelUtil = {}

local FALLBACK_EXPONENT = 1.8

-- Returns XP needed to go from `level` → `level+1`.
function LevelUtil.GetRequiredXP(levelTable: { [number]: number }, level: number): number
	if levelTable[level] then
		return levelTable[level]
	end
	-- Find highest defined entry and scale exponentially above it
	local highestLevel, highestCost = 1, 100
	for lvl, cost in pairs(levelTable) do
		if lvl > highestLevel then
			highestLevel = lvl
			highestCost = cost
		end
	end
	return math.floor(highestCost * (FALLBACK_EXPONENT ^ (level - highestLevel)))
end

-- Adds XP, resolves all level-ups. Returns (newLevel, newXP, levelUps).
function LevelUtil.AddXP(
	levelTable: { [number]: number },
	currentLevel: number,
	currentXP: number,
	xpToAdd: number
): (number, number, number)
	local level = currentLevel
	local xp = currentXP + xpToAdd
	local levelUps = 0

	while true do
		local required = LevelUtil.GetRequiredXP(levelTable, level)
		if xp >= required then
			xp = xp - required
			level = level + 1
			levelUps = levelUps + 1
		else
			break
		end
	end

	return level, xp, levelUps
end

-- Returns 0–1 fill progress.
function LevelUtil.GetProgress(levelTable: { [number]: number }, level: number, xp: number): number
	local req = LevelUtil.GetRequiredXP(levelTable, level)
	return req > 0 and math.clamp(xp / req, 0, 1) or 1
end

-- Returns "1,250 / 5,000 XP"
function LevelUtil.GetProgressString(levelTable: { [number]: number }, level: number, xp: number): string
	local req = LevelUtil.GetRequiredXP(levelTable, level)
	return string.format("%s / %s XP", LevelUtil.Format(xp), LevelUtil.Format(req))
end

-- Formats number with commas: 1000000 → "1,000,000"
function LevelUtil.Format(n: number): string
	local s, result = tostring(math.floor(n)), ""
	for i = 1, #s do
		if i > 1 and (#s - i + 1) % 3 == 0 then
			result = result .. ","
		end
		result = result .. s:sub(i, i)
	end
	return result
end

return LevelUtil
