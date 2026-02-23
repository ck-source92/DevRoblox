local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local RunService = game:GetService("RunService")

local OutfitRepository = {}
OutfitRepository.__index = OutfitRepository

local OutfitEntity = require(ReplicatedStorage.Shared.Classes.Outfits.Domain.OutfitEntity)

function OutfitRepository.new()
	local self = setmetatable({}, OutfitRepository)
	return self
end

function OutfitRepository:Init()
	if RunService:IsServer() then
		self.DataCacheService = Knit.GetService("DataCacheService")
	else
		self.DataCacheController = Knit.GetService("DataCacheController")
	end

	self.DataService = Knit.GetService("DataService")
	self.Template = self.DataCacheService:GetFile("Template")
end

function OutfitRepository:GetTemplateOutfit()
	return self.Template.Outfits
end

function OutfitRepository:GetOutfit(outfitId: number)
	local outfit = self.Template.Outfits[outfitId]
	if not outfit then
		error("Outfit with the specified ID not found.")
	end

	-- Select a random variant if available
	local selectedVariant = nil
	if outfit.Variant and type(outfit.Variant) == "table" and #outfit.Variant > 0 then
		local randomIndex = math.random(1, #outfit.Variant)
		selectedVariant = outfit.Variant[randomIndex]
	end

	local outfitEntity = OutfitEntity.new({
		Id = outfit.Id or outfitId,
		Name = outfit.Name, -- Use full name with prefix (e.g., "Outfit - Student 2")
		DisplayName = outfit.DisplayName,
		Variant = selectedVariant,
		Price = outfit.Price or 0,
	})

	return outfitEntity
end

function OutfitRepository:GetPlayerData(player: Player)
	return self.DataService:GetData(player)
end

function OutfitRepository:UpdatePlayerData(player: Player, key: string, value: any, increment: boolean?)
	return self.DataService:ChangeValue(player, key, value, increment)
end

function OutfitRepository:SaveData(player: Player)
	if self.DataService.SaveData then
		self.DataService:SaveData(player)
	end
end

return OutfitRepository
