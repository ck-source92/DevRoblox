local DodgeResolver = {}

function DodgeResolver.Resolve(playerStats, obstacleStats)
	return {
		success = playerStats.skill >= obstacleStats.skill,
		difference = playerStats.skill - obstacleStats.skill,
	}
end

return DodgeResolver
