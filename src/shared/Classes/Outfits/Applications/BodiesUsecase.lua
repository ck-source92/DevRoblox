local BodiesUsecase = {}
BodiesUsecase.__index = BodiesUsecase

function BodiesUsecase.new(bodiesRepository, rbxBodiesService)
	local self = setmetatable({}, BodiesUsecase)
	self.BodiesRepository = bodiesRepository
	self.RbxBodiesService = rbxBodiesService
	return self
end

--[[
	Applies an outfit's body mesh to a player's character
	@param player: The player whose character will be modified
	@param outfitName: The name of the outfit to apply (e.g., "Student 1")
	@return boolean: Success status
]]
function BodiesUsecase:ApplyBodyToCharacter(player: Player, outfitName: string?, variant: string?)
	local character = player.Character
	if not character then
		warn("[BodiesUsecase] Player has no character")
		return false
	end

	-- If no outfit name provided, skip (could implement default body restoration here)
	if not outfitName or outfitName == "" then
		warn("[BodiesUsecase] No outfit name provided")
		return false
	end

	-- Get the outfit model from repository
	local outfitModel = self.BodiesRepository:GetOutfitModel(outfitName, variant)
	if not outfitModel then
		warn("[BodiesUsecase] Outfit model not found:", outfitName)
		return false
	end

	-- Apply the body mesh using the Roblox service (pass player to track changes)
	local success = self.RbxBodiesService:ApplyBodyMesh(player, character, outfitModel, variant)

	if success then
		print("[BodiesUsecase] Successfully applied body mesh for:", outfitName)
	else
		warn("[BodiesUsecase] Failed to apply body mesh for:", outfitName)
	end

	return success
end

--[[
	Stores the original body of a player when they first join
	@param player: The player whose original body to store
	@return boolean: Success status
]]
function BodiesUsecase:StoreOriginalBody(player: Player)
	local character = player.Character
	if not character then
		warn("[BodiesUsecase] Player has no character")
		return false
	end

	local success = self.RbxBodiesService:StoreOriginalBody(player, character)

	if success then
		print("[BodiesUsecase] Successfully stored original body for:", player.Name)
	else
		warn("[BodiesUsecase] Failed to store original body for:", player.Name)
	end

	return success
end

--[[
	Resets the player's body to the original mesh
	@param player: The player whose character will be reset
	@return boolean: Success status
]]
function BodiesUsecase:ResetToDefaultBody(player: Player)
	local character = player.Character
	if not character then
		warn("[BodiesUsecase] Player has no character")
		return false
	end

	local success = self.RbxBodiesService:RestoreOriginalBody(player, character)

	if success then
		print("[BodiesUsecase] Successfully reset body to default for:", player.Name)
	else
		warn("[BodiesUsecase] Failed to reset body to default for:", player.Name)
	end

	return success
end

return BodiesUsecase
