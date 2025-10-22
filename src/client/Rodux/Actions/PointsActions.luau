local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

local PointsActions = {
	setPoints = Rodux.makeActionCreator("setPoints", function(value)
		return { value = value }
	end),
}

return PointsActions
