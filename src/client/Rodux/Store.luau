-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Packages
local Rodux = require(ReplicatedStorage.Packages.Rodux)

-- Variables
local Reducers = StarterPlayer.StarterPlayerScripts.Client.Rodux.Reducers

-- Reducers
local PointsReducers = require(Reducers.PointReducers)

-- Store
local StoreReducers = Rodux.combineReducers({
	PointsReducers = PointsReducers,
})

local Store = Rodux.Store.new(StoreReducers, nil, {})

return Store
