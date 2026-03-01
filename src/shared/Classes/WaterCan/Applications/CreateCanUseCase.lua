--[[
    CreateCanUseCase  (WaterCan/Application)
    ─────────────────────────────────────────────
    Creates a new level-1 watering can for a player and persists it.

    Depends on IWaterCanRepository (injected) and WaterCanEntity.
--]]

local RS = game:GetService("ReplicatedStorage")

local WaterCanEntity = require(script.Parent.Parent.Domain.WaterCanEntity)
local LevelUtil = require(RS.Shared.Modules.LevelUtil)
local WateringCanData = require(RS.Shared.Data.WateringCanData)

local CreateCanUseCase = {}
CreateCanUseCase.__index = CreateCanUseCase

local _idCounter = 0
local function _newCanId(): string
	_idCounter = _idCounter + 1
	return "can_" .. _idCounter
end

function CreateCanUseCase.new(repo: table)
	assert(repo, "CreateCanUseCase: repo is required")
	return setmetatable({ _repo = repo }, CreateCanUseCase)
end

--- Creates and persists a new can. Returns the new WateringCanEntity.
function CreateCanUseCase:Execute(player: Player): table
	assert(self._repo.HasPlayer(player), "CreateCanUseCase: player not initialised in repository")

	local canId = _newCanId()
	local can = WaterCanEntity.new(canId, LevelUtil, WateringCanData.LevelTable)

	self._repo:SaveCan(player, can)
	return can
end

return CreateCanUseCase
