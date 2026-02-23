-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit packages
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local OutfitService

local OutfitController = Knit.CreateController({
	Name = "OutfitController",
})

function OutfitController:KnitInit()
	OutfitService = Knit.GetService("OutfitService")
	-- self.NotificationController = Knit.GetController("NotificationController")
end

function OutfitController:Buy(outfitId: number)
	OutfitService:Buy(outfitId)
		:andThen(function(result)
			if result and result.type == "ERROR" then
				print("[OutfitController] Failed to buy outfit: ", result.text)
				-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
				elseif result and result.type == "SUCCESS" then
					print("[OutfitController] Successfully bought outfit: ", result.text)
				-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
			end
		end)
		:catch(function(err)
			warn("[OutfitController] Error buying outfit:", err)
			-- self.NotificationController:Notify({ tag = "Outfit", text = "Failed to purchase outfit", type = "ERROR" })
		end)
end

function OutfitController:Equip(outfitId: number, SkipApplyMesh: boolean?)
	return OutfitService:Equip(outfitId, SkipApplyMesh):andThen(function(result)
		if result and result.type == "ERROR" then
			print("[OutfitController] Failed to equip outfit: ", result.text)
			-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
		elseif result and result.type == "SUCCESS" then
			print("[OutfitController] Successfully equipped outfit: ", result.text)
			-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
		end
	end)
end

function OutfitController:EquipCurrentOutfit()
	return OutfitService:EquipCurrentOutfit():andThen(function(result)
		if result and result.type == "ERROR" then
			print("[OutfitController] Failed to equip current outfit: ", result.text)
			-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
		elseif result and result.type == "SUCCESS" then
			print("[OutfitController] Successfully equipped current outfit: ", result.text)
			-- self.NotificationController:Notify({ tag = "Outfit", text = result.text, type = result.type })
		end
	end)
end

function OutfitController:ResetOutfit()
	return OutfitService:ResetOutfit()
end

function OutfitController:GetPlayerOutfitId()
	return OutfitService:GetPlayerOutfitId()
end

function OutfitController:KnitStart()
	game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Eight then
			print("Equip outfit")
			self:EquipCurrentOutfit()
			-- self:GetPlayerOutfitId()
		end
	end)
end

return OutfitController
