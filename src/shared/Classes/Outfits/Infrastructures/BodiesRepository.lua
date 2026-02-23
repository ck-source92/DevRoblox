local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local RunService = game:GetService("RunService")

local BodiesRepository = {}
BodiesRepository.__index = BodiesRepository

local BodyEntity = require(ReplicatedStorage.Shared.Classes.Outfits.Domain.BodiesEntity)

function BodiesRepository.new()
	local self = setmetatable({}, BodiesRepository)
	return self
end

function BodiesRepository:Init()
	if RunService:IsServer() then
		self.DataCacheService = Knit.GetService("DataCacheService")
	else
		self.DataCacheController = Knit.GetService("DataCacheController")
	end

	self.Template = self.DataCacheService:GetFile("Template")
end

function BodiesRepository:GetTemplateBody()
	return self.Template.Bodies
end

function BodiesRepository:GetBody(bodyId: number)
	local body = self.Template.Bodies[bodyId]
	if not body then
		error("Body with the specified ID not found.")
	end

	local bodyEntity = BodyEntity.new({
		Id = body.Id or bodyId,
		Name = body.Name,
		DisplayName = body.DisplayName,
	})

	return bodyEntity
end

function BodiesRepository:GetOutfitModel(outfitName: string, variant: string?)
	local replicatedAssets = ReplicatedStorage:FindFirstChild("Assets")
	if not replicatedAssets then
		warn("[BodiesRepository] Assets folder not found")
		return nil
	end

	local OutfitsFolder = replicatedAssets:FindFirstChild("Outfits")
	if not OutfitsFolder then
		warn("[BodiesRepository] Outfits folder not found")
		return nil
	end

	local cosmeticsFolder = OutfitsFolder:FindFirstChild("CosmeticsSystem")
	if not cosmeticsFolder then
		warn("[BodiesRepository] CosmeticsSystem folder not found")
		return nil
	end

	-- Try variant-based path first: /Assets/CosmeticsSystem/{variant}/{outfitName}
	if variant and variant ~= "" then
		local variantFolder = cosmeticsFolder:FindFirstChild(variant)
		if variantFolder then
			local model = variantFolder:FindFirstChild(outfitName)
			if model and model:IsA("Model") then
				print("[BodiesRepository] Found outfit model at variant path:", variant, "/", outfitName)
				return model
			end
		end
		warn("[BodiesRepository] Outfit not found at variant path:", variant, "/", outfitName)
	end

	-- Fallback: Try direct path (for outfits without variants)
	local model = cosmeticsFolder:FindFirstChild(outfitName)
	if model and model:IsA("Model") then
		print("[BodiesRepository] Found outfit model at fallback path:", outfitName)
		return model
	end

	warn("[BodiesRepository] Outfit model not found:", outfitName)
	return nil
end

return BodiesRepository
