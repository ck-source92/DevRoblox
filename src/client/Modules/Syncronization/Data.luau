-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Rodux = require(ReplicatedStorage.Packages.Rodux)

-- Properties
local Data = {}

local Actions = StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions

-- Actions
local PointsActions = require(Actions.PointsActions)

-- Functions
function Data:Init()
	local PointsService = Knit.GetService("PointService")

	PointsService.PointsChanged:Connect(function(points: table)
		Store.dispatch(PointsActions.setPoints(points.points))
	end)
end

return Data
