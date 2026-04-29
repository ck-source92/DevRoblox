local Stats = {}
Stats.__index = Stats

function Stats.new(skill, speed)
	assert(type(skill) == "number", "skill harus number")
	assert(type(speed) == "number", "speed harus number")

	return setmetatable({
		skill = math.clamp(skill, 0, 100),
		speed = math.clamp(speed, 0, 100),
	}, Stats)
end

function Stats:WithSpeed(newSpeed)
	return Stats.new(self.skill, newSpeed)
end

function Stats:IsStrongerThan(otherStats)
	return self.skill > otherStats.skill
end

return Stats
