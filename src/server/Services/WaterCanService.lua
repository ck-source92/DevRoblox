--[[
    WaterCanService  (ServerScriptService)
    ──────────────────────────────────────────
    Knit service. Thin network layer — delegates all logic to use cases.

    Responsibilities:
      • Own the WateringCanRepository instance
      • Expose CreateCan / AddXP / GetInventory to MachineService and client
      • Fire client signals for UI updates
      • Handle player lifecycle (init / remove)
--]]

local RS = game:GetService("ReplicatedStorage")
local Knit = require(RS.Packages.Knit)
local Players = game:GetService("Players")

local WaterCanRepository = require(RS.Shared.Classes.WaterCan.Infrasturcture.WaterCanRepository)
local CreateCanUseCase = require(RS.Shared.Classes.WaterCan.Applications.CreateCanUseCase)
local AddXPUseCase = require(RS.Shared.Classes.WaterCan.Applications.AddXPUseCase)
local WateringCanData = require(RS.Shared.Data.WateringCanData)

-- ── Debug mode ────────────────────────────────────────────────────────────────
-- true  = print every XP gain and level-up to output (development)
-- false = silent (production)
local DEBUG_MODE = false

local function DebugLog(...)
	if DEBUG_MODE then
		print("[WateringCanService DEBUG]", ...)
	end
end

local WaterCanService = Knit.CreateService({
	Name = "WaterCanService",
	Client = {
		CanXPUpdated = Knit.CreateSignal(), -- (canId, newXP, newLevel)
		CanLeveledUp = Knit.CreateSignal(), -- (canId, newLevel, tierName)
		InventorySync = Knit.CreateSignal(), -- (snapshot)
		CanPickedUp = Knit.CreateSignal(), -- (canId, level, tierName)
	},
})

function WaterCanService:KnitInit()
	self._repo = WaterCanRepository.new()
	self._createUC = CreateCanUseCase.new(self._repo)
	self._addXPUC = AddXPUseCase.new(self._repo)
end

function WaterCanService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self._repo:InitPlayer(player)
		-- TODO: replace with DataStore load
		self:CreateCan(player)
		self:CreateCan(player)
		self.Client.InventorySync:Fire(player, self._repo:GetInventorySnapshot(player))
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- TODO: save to DataStore before clearing
		self._repo:RemovePlayer(player)
	end)
end

function WaterCanService.Client:GetInventory(player: Player): table
	return self.Server._repo:GetInventorySnapshot(player)
end

function WaterCanService.Client:GetCan(player: Player, canId: string): table?
	local can = self.Server._repo:GetCan(player, canId)
	return can and can:Serialize()
end

function WaterCanService:GetRepo(): table
	return self._repo
end

function WaterCanService:AddXP(player: Player, canId: string, xpAmount: number): table?
	local result = self._addXPUC:Execute(player, canId, xpAmount)
	if not result then
		return nil
	end

	DebugLog(
		string.format(
			"AddXP  player=%-16s  can=%-8s  +%6.0f XP  lvl=%-3d  xp=%d",
			player.Name,
			canId,
			xpAmount,
			result.newLevel,
			result.newXP
		)
	)

	self.Client.CanXPUpdated:Fire(player, canId, result.newXP, result.newLevel)

	if result.levelUps > 0 then
		local tierName = WateringCanData.GetTierName(result.newLevel)
		DebugLog(string.format("LEVEL UP  can=%-8s  newLevel=%-3d  tier=%s", canId, result.newLevel, tierName))
		self.Client.CanLeveledUp:Fire(player, canId, result.newLevel, tierName)
	end

	return result
end

function WaterCanService:CreateCan(player: Player): table
	return self._createUC:Execute(player)
end

function WaterCanService:GetInventorySnapshot(player: Player): table
	return self._repo:GetInventorySnapshot(player)
end

return WaterCanService
