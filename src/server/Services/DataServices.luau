-- Knit Packages
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ProfileService
local ServerModules = script.Parent.Parent.Modules
local ProfileService = require(ServerModules.ProfileService)
local ProfileTemplate = require(ServerScriptService.Server.Constant.DataTemplate)
local ProfileStore = ProfileService.GetProfileStore("DataTest_1_01", ProfileTemplate)

-- DataService
local DataService = Knit.CreateService({
	Name = "DataService",
	DataChanged = Knit.CreateSignal(),

	Client = {
		DataChanged = Knit.CreateSignal(),
		GetData = Knit.CreateSignal(),
	},

	Profiles = {},
})

--|| Client Functions ||--

--[=[
	Returns player data to client
]=]
function DataService.Client:GetData(player: Player): {} | nil
	return self.Server:GetData(player)
end

--|| Local Functions ||--

--[=[
	Do someone with profile data when loaded
	Cache profile to DataService.Profiles
]=]
local function InitAndCacheProfile(player: Player, profile: {})
	DataService.Profiles[player] = profile
end

--[=[
	Load player data on player added
]=]
local function LoadData(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			DataService.Profiles[player] = nil
			player:Kick("Data loaded on another server. Please rejoin!")
		end)
		if player:IsDescendantOf(Players) == true then
			InitAndCacheProfile(player, profile)
		else
			profile:Release()
		end
	else
		player:Kick("Datastore error. Please rejoin!")
	end
end

--[=[
	Save player data on player removing
]=]
function DataService:SaveData(player: Player)
	local profile = DataService.Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
	DataService.Profiles[player] = nil
	print(player.Name .. "'s Data Succesfully Saved!")
end

--|| Server Functions ||--

--[=[
	Returns player data
	Yields if player profile doesn't exist
	Returns nil if player leaves during yield
]=]
function DataService:GetData(player: Player): {} | nil
	local playerProfile = self.Profiles[player]
	if playerProfile == nil then
		repeat
			task.wait(1)
			playerProfile = self.Profiles[player]
		until playerProfile ~= nil or player.Parent == nil
	end
	if playerProfile ~= nil then
		return playerProfile.Data
	else
		return nil
	end
end

--[=[
	Initializes player added and removing events
]=]
function DataService:KnitInit()
	local function playerAdded(player: Player)
		LoadData(player)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		LoadData(player)
	end
	Players.PlayerAdded:Connect(playerAdded)

	local function playerRemoving(player: Player)
		self:SaveData(player)
	end
	Players.PlayerRemoving:Connect(playerRemoving)
end

return DataService
