-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rodux = require(ReplicatedStorage.Packages.Rodux)

-- Trail Reducers
local PointReducers = Rodux.createReducer({
	Points = {},
	CurrentPoints = 0,
}, {
	setPoints = function(state, action)
		local newState = table.clone(state)
		newState.CurrentPoints = action.value
		return newState
	end,
	addPoints = function(state, action)
		local newState = table.clone(state)
		newState.Point = action.values
		return newState
	end
})

return PointReducers
