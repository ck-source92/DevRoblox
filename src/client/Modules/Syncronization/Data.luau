-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Actions
local Actions = StarterPlayer.StarterPlayerScripts.Client.Rodux.Actions
local PointsActions = require(Actions.PointsActions)

-- Properties
local Data = {}

-- Functions
function Data:Init()
	print("[Data] Started")
	local DataService = Knit.GetService("DataService")

	DataService:GetData():andThen(function(data)
		Store:dispatch(PointsActions.setPoints(1))
	end)

	print("[Data] Data Player : ", Data)

	print("[Data] Finish")
end

return Data
