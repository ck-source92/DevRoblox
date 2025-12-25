--!strict
-- Infrastructure/PointsRepository.luau
-- Handles data saving/loading via ProfileService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService.Server.Modules.ProfileService)
local Wallet = require(ReplicatedStorage.Shared.Features.Points.Domain.Wallet)

local PointsRepository = {}
PointsRepository.__index = PointsRepository

-- Defines the save structure
local PROFILE_TEMPLATE = {
	Points = 0,
}

local ProfileStore = ProfileService.GetProfileStore("PointsData_v1", PROFILE_TEMPLATE)

function PointsRepository.new()
	local self = setmetatable({}, PointsRepository)
	self._profiles = {} -- [Player] = Profile
	return self
end

function PointsRepository:LoadProfile(player: Player): any
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			self._profiles[player] = nil
			player:Kick("Profile released")
		end)

		if player:IsDescendantOf(game.Players) then
			self._profiles[player] = profile
			return profile
		else
			profile:Release()
		end
	else
		player:Kick("Cloud data failure")
	end
	return nil
end

function PointsRepository:GetProfile(player: Player)
	return self._profiles[player]
end

function PointsRepository:ReleaseProfile(player: Player)
	local profile = self._profiles[player]
	if profile then
		profile:Release()
	end
end

return PointsRepository
