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
	local PointsService = Knit.GetService("PointService")

	-- local success, points = pcall(function()
	-- 	return PointsService:GetPoints() -- Knit automatically sends LocalPlayer
	-- end)

	-- if success then
	-- 	print("[Data] Initial points:", points)
	-- 	Store:dispatch(PointsActions.setPoints(10))
	-- else
	-- 	warn("[Data] Failed to get points:", points)
	-- end

	DataService:GetData():andThen(function(data)
		Store:dispatch(PointsActions.setPoints(1))
		-- PointsService.PointsChanged:Connect(function(player, points)
		print("[point] point : ", data.points)

		-- end)
	end)

	print("[Data] Finish")
end

return Data
