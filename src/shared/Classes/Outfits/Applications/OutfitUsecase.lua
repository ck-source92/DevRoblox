local RunService = game:GetService("RunService")

local OutfitUsecase = {}
OutfitUsecase.__index = OutfitUsecase

function OutfitUsecase.new(outfitRepository, bodiesUsecase)
	local self = setmetatable({}, OutfitUsecase)
	self.OutfitRepository = outfitRepository
	self.BodiesUsecase = bodiesUsecase
	-- Cache player variants (key: UserId, value: variant string)
	self.PlayerVariants = {}
	return self
end

function OutfitUsecase:BuyItem(player: Player, outfitId: number, ignoreCost: boolean?)
	local data = self.OutfitRepository:GetPlayerData(player)
	if not data then
		error("Player data not found.")
	end

	local outfit = self.OutfitRepository:GetOutfit(outfitId)
	if not outfit then
		error("Outfit not found.")
	end

	local price = outfit.price or 0

	if not ignoreCost then
		if data.Money2 < price then
			return { text = "Not enough money", type = "ERROR" }
		end
	end

	if not ignoreCost then
		-- Note: LogIGPEconomyEvent should be handled by the caller or a logger service
		self.OutfitRepository:UpdatePlayerData(player, "Money2", -price, true)
	end

	table.insert(data.Outfits.Unlocked, outfitId)
	data.Outfits.Current = outfitId

	return {
		text = `Outfit {outfit.displayName} purchased and equipped!`,
		type = "SUCCESS",
		data = {
			Unlocked = data.Outfits.Unlocked,
			Current = data.Outfits.Current,
		},
	}
end

function OutfitUsecase:Equip(player: Player, outfitId: number, SkipApplyMesh: boolean?)
	local data = self.OutfitRepository:GetPlayerData(player)
	if data == nil then
		return { text = "Player has no data", type = "ERROR" }
	end

	local result
	if outfitId ~= 0 then
		local outfit = self.OutfitRepository:GetOutfit(outfitId)
		if outfit == nil then
			return { text = "This outfit doesn't exist", type = "ERROR" }
		end

		if not table.find(data.Outfits.Unlocked, outfitId) then
			return { text = "You don't own this outfit", type = "ERROR" }
		end

		data.Outfits.Current = outfitId

		-- Store the variant for this player
		self.PlayerVariants[player.UserId] = outfit.variant
		print("[OutfitUsecase] Stored variant for player:", player.Name, "variant:", outfit.variant)

		result = {
			text = `Equipped {outfit.displayName}'s outfit`,
			type = "SUCCESS",
			data = {
				Unlocked = data.Outfits.Unlocked,
				Current = data.Outfits.Current,
			},
		}

		-- Apply body mesh if on server
		if not SkipApplyMesh then
			if RunService:IsServer() and self.BodiesUsecase then
				self.BodiesUsecase:ApplyBodyToCharacter(player, outfit.name, outfit.variant)
			end
		end
	else
		data.Outfits.Current = outfitId
		result = {
			text = `Unequipped outfit`,
			type = "SUCCESS",
			data = {
				Unlocked = data.Outfits.Unlocked,
				Current = data.Outfits.Current,
			},
		}

		-- Reset body to original if on server
		if RunService:IsServer() and self.BodiesUsecase then
			self.BodiesUsecase:ResetToDefaultBody(player)
		end
	end

	return result
end

function OutfitUsecase:EquipCurrentOutfit(player: Player)
	local data = self.OutfitRepository:GetPlayerData(player)
	if data == nil then
		return { text = "Player has no data", type = "ERROR" }
	end

	local outfitId = data.Outfits.Current
	print("[OutfitUsecase] EquipCurrentOutfit outfitId: " .. outfitId)
	local result
	if outfitId ~= 0 then
		local outfit = self.OutfitRepository:GetOutfit(outfitId)
		if outfit == nil then
			return { text = "This outfit doesn't exist", type = "ERROR" }
		end

		if not table.find(data.Outfits.Unlocked, outfitId) then
			return { text = "You don't own this outfit", type = "ERROR" }
		end

		-- Use cached variant if available, otherwise use the new one from GetOutfit
		local cachedVariant = self.PlayerVariants[player.UserId]
		local variantToUse = cachedVariant or outfit.variant

		-- Only update cache if no variant was cached (prevents overwriting)
		if not cachedVariant then
			self.PlayerVariants[player.UserId] = variantToUse
			print(
				"[OutfitUsecase] EquipCurrentOutfit stored variant for player:",
				player.Name,
				"variant:",
				variantToUse
			)
		else
			print(
				"[OutfitUsecase] EquipCurrentOutfit using cached variant for player:",
				player.Name,
				"variant:",
				variantToUse
			)
		end

		result = {
			text = `Equipped {outfit.displayName}'s outfit`,
			type = "SUCCESS",
			data = {
				Unlocked = data.Outfits.Unlocked,
				Current = data.Outfits.Current,
			},
		}

		-- Apply body mesh if on server (use the consistent variant)
		if RunService:IsServer() and self.BodiesUsecase then
			self.BodiesUsecase:ApplyBodyToCharacter(player, outfit.name, variantToUse)
		end
	else
		result = {
			text = `Unequipped outfit`,
			type = "SUCCESS",
			data = {
				Unlocked = data.Outfits.Unlocked,
				Current = data.Outfits.Current,
			},
		}

		-- Reset body to original if on server
		if RunService:IsServer() and self.BodiesUsecase then
			self.BodiesUsecase:ResetToDefaultBody(player)
		end
	end

	return result
end

function OutfitUsecase:ResetOutfit(player: Player)
	self.BodiesUsecase:ResetToDefaultBody(player)
end

function OutfitUsecase:GetPlayerOutfitId(player: Player)
	local data = self.OutfitRepository:GetPlayerData(player)
	if data == nil then
		return 0
	end
	return data.Outfits.Current
end

function OutfitUsecase:GetPlayerOutfitIdAndVariant(player: Player)
	local data = self.OutfitRepository:GetPlayerData(player)
	if data == nil then
		return { outfitId = 0, variant = nil }
	end

	local outfitId = data.Outfits.Current
	local variant = self.PlayerVariants[player.UserId]

	-- If no cached variant but player has an outfit, fetch and cache a variant
	if variant == nil and outfitId ~= 0 then
		local outfit = self.OutfitRepository:GetOutfit(outfitId)
		if outfit and outfit.variant then
			variant = outfit.variant
			self.PlayerVariants[player.UserId] = variant
			print(
				"[OutfitUsecase] GetPlayerOutfitIdAndVariant: Fetched and cached variant for player:",
				player.Name,
				"variant:",
				variant
			)
		end
	end

	print("[OutfitUsecase] GetPlayerOutfitIdAndVariant:", player.Name, "outfitId:", outfitId, "variant:", variant)
	return { outfitId = outfitId, variant = variant }
end

function OutfitUsecase:CleanPlayerVariants(player: Player)
	self.PlayerVariants[player.UserId] = nil
end

return OutfitUsecase
