-- Knit Packages
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
-- local FunnelsModule = require(ReplicatedStorage.Packages.funnelsModule)

local OutfitRepository = require(ReplicatedStorage.Shared.Classes.Outfits.Infrastructures.OutfitRepository)
local OutfitUsecase = require(ReplicatedStorage.Shared.Classes.Outfits.Applications.OutfitUsecase)

local BodiesRepository = require(ReplicatedStorage.Shared.Classes.Outfits.Infrastructures.BodiesRepository)
local BodiesUsecase = require(ReplicatedStorage.Shared.Classes.Outfits.Applications.BodiesUsecase)
local RbxBodiesService = require(ReplicatedStorage.Shared.Classes.Outfits.RbxBodiesService)

-- Mock Test Service (for development/testing)
local RbxMockTestService = require(ReplicatedStorage.Shared.Classes.Outfits.RbxMockTestService)

local OutfitService = Knit.CreateService({
	Name = "OutfitService",
	Client = {
		OutfitUpdated = Knit.CreateSignal(),
	},
})

function OutfitService:KnitInit() end

function OutfitService:KnitStart()
	-- Initialize repositories
	self.outfitRepository = OutfitRepository.new()
	self.outfitRepository:Init()

	self.bodiesRepository = BodiesRepository.new()
	self.bodiesRepository:Init()

	-- Initialize Roblox-specific service
	self.rbxBodiesService = RbxBodiesService.new()

	-- Initialize use cases with dependency injection
	self.bodiesUsecase = BodiesUsecase.new(self.bodiesRepository, self.rbxBodiesService)
	self.usecase = OutfitUsecase.new(self.outfitRepository, self.bodiesUsecase)

	-- Hook into character loading to store original bodies
	local function onCharacterAdded(player: Player, character: Model)
		task.wait(0.5)
		self.bodiesUsecase:StoreOriginalBody(player)
	end

	local function onPlayerAdded(player: Player)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end

		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
	end

	local function onPlayerRemoving(player: Player)
		self:CleanPlayerVariants(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	--#region Debug
	--[[ Start outfit cycling test (controlled by ENABLE_OUTFIT_TEST flag in RbxMockTestService)
	if GameConfig.ENABLE_DEBUG then
		RbxMockTestService:Start()
	end
	]]--
	--#endregion
end

function OutfitService.Client:Buy(player: Player, outfitId: number, ignoreCost: boolean?)
	return self.Server:Buy(player, outfitId, ignoreCost)
end

function OutfitService.Client:Equip(player: Player, outfitId: number, SkipApplyMesh: boolean?)
	return self.Server:Equip(player, outfitId, SkipApplyMesh)
end

function OutfitService.Client:EquipCurrentOutfit(player: Player)
	return self.Server:EquipCurrentOutfit(player)
end

function OutfitService.Client:ResetOutfit(player: Player)
	return self.Server:ResetOutfit(player)
end

function OutfitService.Client:GetPlayerOutfitId(player: Player)
	return self.Server:GetPlayerOutfitId(player)
end

function OutfitService:GetPlayerOutfitId(player: Player)
	return self.usecase:GetPlayerOutfitId(player)
end

function OutfitService:GetPlayerOutfitIdAndVariant(player: Player)
	return self.usecase:GetPlayerOutfitIdAndVariant(player)
end

function OutfitService:Buy(player: Player, outfitId: number, ignoreCost: boolean?)
	local result = self.usecase:BuyItem(player, outfitId, ignoreCost)
	--[[if result.type == "SUCCESS" then
		if not ignoreCost then
			local outfit = self.outfitRepository:GetOutfit(outfitId)
			local data = self.outfitRepository:GetPlayerData(player)
			FunnelsModule:LogIGPEconomyEvent(player, "Money2", outfit.price, data.Money2, outfit.name)
		end
		self.Client.OutfitUpdated:Fire(player, result.data)
	end
	--]]--
	return result
end

function OutfitService:Equip(player: Player, outfitId: number, SkipApplyMesh: boolean?)
	local result = self.usecase:Equip(player, outfitId, SkipApplyMesh)
	if result.type == "SUCCESS" then
		self.Client.OutfitUpdated:Fire(player, result.data)
	end
	return result
end

function OutfitService:EquipCurrentOutfit(player: Player)
	local result = self.usecase:EquipCurrentOutfit(player)
	if result.type == "SUCCESS" then
		self.Client.OutfitUpdated:Fire(player, result.data)
	end
	return result
end

function OutfitService:ResetOutfit(player: Player)
	self.usecase:ResetOutfit(player)
end

function OutfitService:CleanPlayerVariants(player: Player)
	self.usecase:CleanPlayerVariants(player)
end

return OutfitService
