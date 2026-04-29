local KickResolver = {}

local GOAL_WIDTH = 8 -- studs

function KickResolver.ResolveTarget(goalCenterPosition)
	local randomX = goalCenterPosition.X + math.random(-GOAL_WIDTH / 2, GOAL_WIDTH / 2)

	return Vector3.new(randomX, goalCenterPosition.Y, goalCenterPosition.Z)
end

return KickResolver
