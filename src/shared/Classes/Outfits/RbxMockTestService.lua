--[[
	Mock Test for Outfit System
	This script automatically cycles through outfits every 5 seconds for testing purposes.
	To enable: Set ENABLE_OUTFIT_TEST to true
	To disable: Set ENABLE_OUTFIT_TEST to false
	
	Updated to match RbxBodiesService structure and methods.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Configuration
local ENABLE_OUTFIT_TEST = false -- Set to false to disable auto outfit testing
local CYCLE_INTERVAL = 6 -- Seconds between outfit changes
local OUTFIT_IDS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 } -- Outfit IDs to cycle through

local R15_PARTS = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
}

local OutfitMockTest = {}
OutfitMockTest.__index = OutfitMockTest

function OutfitMockTest.new()
	local self = setmetatable({}, OutfitMockTest)

	self.OriginalBodies = {}
	-- Track which players have actually changed their outfit
	self.OutfitChanged = {}

	return self
end

function OutfitMockTest:StoreOriginalBody(player: Player, character: Model)
	if not player or not character then
		warn("[OutfitMockTest] Invalid player or character")
		return false
	end

	local userId = player.UserId
	self.OriginalBodies[userId] = {
		Parts = {},
		Clothing = {},
		BodyColors = nil,
		Accessories = {},
		Motor6DTransforms = {},
		HumanoidDescription = nil,
	}

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ok, description = pcall(function()
			return humanoid:GetAppliedDescription()
		end)
		if ok then
			self.OriginalBodies[userId].HumanoidDescription = description
		else
			warn("[OutfitMockTest] Failed to get HumanoidDescription for storing original body:", tostring(description))
		end
	end

	for _, partName in ipairs(R15_PARTS) do
		local part = character:FindFirstChild(partName)
		if part then
			local clonedPart = part:Clone()

			-- Remove Motor6D and Attachments, but preserve other important children like Decals
			for _, child in ipairs(clonedPart:GetChildren()) do
				if child:IsA("Attachment") or child:IsA("Motor6D") then
					child:Destroy()
				end
				-- Keep Decals (like face), MeshParts, SpecialMesh, etc.
			end

			self.OriginalBodies[userId].Parts[partName] = clonedPart
		end
	end

	local shirt = character:FindFirstChildOfClass("Shirt")
	local pants = character:FindFirstChildOfClass("Pants")

	if shirt then
		self.OriginalBodies[userId].Clothing.Shirt = shirt:Clone()
	end

	if pants then
		self.OriginalBodies[userId].Clothing.Pants = pants:Clone()
	end

	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		self.OriginalBodies[userId].BodyColors = bodyColors:Clone()
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			table.insert(self.OriginalBodies[userId].Accessories, child:Clone())
		end
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			self.OriginalBodies[userId].Motor6DTransforms[descendant.Name] = {
				C0 = descendant.C0,
				C1 = descendant.C1,
				Part0Name = descendant.Part0 and descendant.Part0.Name or nil,
				Part1Name = descendant.Part1 and descendant.Part1.Name or nil,
			}
		end
	end

	print("[OutfitMockTest] Stored original body for:", player.Name)
	return true
end

function OutfitMockTest:RestoreOriginalBody(player: Player, character: Model)
	if not player or not character then
		warn("[OutfitMockTest] Invalid player or character")
		return false
	end

	local userId = player.UserId

	-- Check if player ever changed outfit - if not, skip restore
	if not self.OutfitChanged[userId] then
		print("[OutfitMockTest] Player", player.Name, "never changed outfit - skipping restore")
		return true -- Return true since no restore needed
	end

	local originalBody = self.OriginalBodies[userId]

	if not originalBody then
		warn("[OutfitMockTest] No original body stored for:", player.Name)
		return false
	end

	if not originalBody.Parts then
		warn("[OutfitMockTest] Original body data has old format. Player needs to respawn for new format.")
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[OutfitMockTest] No Humanoid found in character")
		return false
	end

	-- Temporarily disable BreakJointsOnDeath to prevent character death during part replacement
	local originalBreakJoints = humanoid.BreakJointsOnDeath
	humanoid.BreakJointsOnDeath = false

	for _, partName in ipairs(R15_PARTS) do
		local currentPart = character:FindFirstChild(partName)
		local originalPart = originalBody.Parts[partName]

		if currentPart and originalPart then
			self:_replacePart(character, currentPart, originalPart, partName, nil)
		end
	end

	if originalBody.Motor6DTransforms then
		for motorName, transformData in pairs(originalBody.Motor6DTransforms) do
			local motor6D = nil
			for _, descendant in ipairs(character:GetDescendants()) do
				if descendant:IsA("Motor6D") and descendant.Name == motorName then
					local part0Match = not transformData.Part0Name
						or (descendant.Part0 and descendant.Part0.Name == transformData.Part0Name)
					local part1Match = not transformData.Part1Name
						or (descendant.Part1 and descendant.Part1.Name == transformData.Part1Name)

					if part0Match and part1Match then
						motor6D = descendant
						break
					end
				end
			end

			if motor6D then
				motor6D.C0 = transformData.C0
				motor6D.C1 = transformData.C1
			end
		end
	end

	local currentShirt = character:FindFirstChildOfClass("Shirt")
	local currentPants = character:FindFirstChildOfClass("Pants")

	if currentShirt then
		currentShirt:Destroy()
	end
	if currentPants then
		currentPants:Destroy()
	end

	if originalBody.Clothing.Shirt then
		originalBody.Clothing.Shirt:Clone().Parent = character
	end

	if originalBody.Clothing.Pants then
		originalBody.Clothing.Pants:Clone().Parent = character
	end

	if originalBody.BodyColors then
		local currentBodyColors = character:FindFirstChildOfClass("BodyColors")
		if currentBodyColors then
			currentBodyColors:Destroy()
		end
		originalBody.BodyColors:Clone().Parent = character
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end

	for _, accessory in ipairs(originalBody.Accessories) do
		local accessoryClone = accessory:Clone()
		humanoid:AddAccessory(accessoryClone)
	end

	-- Restore BreakJointsOnDeath setting
	humanoid.BreakJointsOnDeath = originalBreakJoints

	-- Reset outfit changed flag since we've restored to original
	self.OutfitChanged[userId] = false

	humanoid:ApplyDescriptionAsync(originalBody.HumanoidDescription)

	print("[OutfitMockTest] Restored original body for:", player.Name)
	return true
end

function OutfitMockTest:ApplyBodyMesh(player: Player, character: Model, outfitModel: Model)
	if not character or not outfitModel then
		warn("[OutfitMockTest] Invalid character or outfit model")
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[OutfitMockTest] No Humanoid found in character")
		return false
	end

	-- Mark that this player has changed their outfit
	if player then
		local userId = player.UserId
		self.OutfitChanged[userId] = true
		print("[OutfitMockTest] Marked outfit as changed for:", player.Name)
	end

	-- Temporarily disable BreakJointsOnDeath to prevent character death during part replacement
	local originalBreakJoints = humanoid.BreakJointsOnDeath
	humanoid.BreakJointsOnDeath = false

	for _, partName in ipairs(R15_PARTS) do
		local oldPart = character:FindFirstChild(partName)
		local newPart = outfitModel:FindFirstChild(partName)

		if oldPart and newPart then
			self:_replacePart(character, oldPart, newPart, partName, outfitModel)
		end
	end

	self:_applyHumanoidDescription(character, outfitModel)
	self:_applyClothing(character, outfitModel)
	self:_applyBodyColors(character, outfitModel)
	self:_applyAccessories(character, outfitModel)

	-- Restore BreakJointsOnDeath setting
	humanoid.BreakJointsOnDeath = originalBreakJoints

	return true
end

function OutfitMockTest:_applyHumanoidDescription(character: Model, outfitModel: Model)
	if not character or not outfitModel then
		warn("[OutfitMockTest] Invalid character or outfit model")
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[OutfitMockTest] No Humanoid found in character")
		return false
	end

	local description: HumanoidDescription?
	local outfitHumanoid = outfitModel:FindFirstChildOfClass("Humanoid")
	if outfitHumanoid then
		local ok, applied = pcall(function()
			return outfitHumanoid:GetAppliedDescription()
		end)
		if ok then
			description = applied
		end
	end

	if not description then
		warn("[OutfitMockTest] Outfit model has no HumanoidDescription and no Humanoid:GetAppliedDescription()")
		return false
	end

	local clonedDescription = description:Clone()
	local ok, err = pcall(function()
		humanoid:ApplyDescriptionAsync(clonedDescription)
	end)
	if not ok then
		warn("[OutfitMockTest] Failed to apply HumanoidDescription:", tostring(err))
		return false
	end

	return true
end

function OutfitMockTest:_replacePart(
	character: Model,
	oldPart: BasePart,
	newPart: BasePart,
	partName: string,
	outfitModel: Model
)
	local clonedPart = newPart:Clone()
	clonedPart.CFrame = oldPart.CFrame
	clonedPart.Name = partName

	for _, child in ipairs(clonedPart:GetChildren()) do
		if child:IsA("Motor6D") or child:IsA("Attachment") then
			child:Destroy()
		end
	end

	for _, child in ipairs(oldPart:GetChildren()) do
		if child:IsA("Attachment") then
			local attachmentClone = child:Clone()
			attachmentClone.Parent = clonedPart
		end
	end

	local outfitMotor6Ds = {}
	if outfitModel then
		for _, child in ipairs(outfitModel:GetDescendants()) do
			if child:IsA("Motor6D") then
				local part0Name = child.Part0 and child.Part0.Name or ""
				local part1Name = child.Part1 and child.Part1.Name or ""
				local key = part0Name .. "_" .. part1Name
				outfitMotor6Ds[key] = {
					C0 = child.C0,
					C1 = child.C1,
					Name = child.Name,
				}
			end
		end
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local isDependent = false

			local originalC0 = descendant.C0
			local originalC1 = descendant.C1

			local part0Name = descendant.Part0 and descendant.Part0.Name or ""
			local part1Name = descendant.Part1 and descendant.Part1.Name or ""
			local motorKey = part0Name .. "_" .. part1Name
			local outfitMotorData = outfitMotor6Ds[motorKey]

			if descendant.Part1 == oldPart then
				descendant.Part1 = clonedPart
				isDependent = true
			end

			if descendant.Part0 == oldPart then
				descendant.Part0 = clonedPart
				isDependent = true
			end

			if isDependent and descendant.Parent == oldPart then
				descendant.Parent = clonedPart
			end

			if isDependent then
				if outfitMotorData then
					descendant.C0 = outfitMotorData.C0
					descendant.C1 = outfitMotorData.C1
				else
					descendant.C0 = originalC0
					descendant.C1 = originalC1
				end
			end
		end
	end

	if partName == "Head" then
		-- Preserve the face decal from old head if cloned head doesn't have one
		if not clonedPart:FindFirstChild("face") then
			local oldFace = oldPart:FindFirstChild("face")
			if oldFace and oldFace:IsA("Decal") then
				local faceClone = oldFace:Clone()
				faceClone.Parent = clonedPart
				print("[OutfitMockTest] Preserved face decal from old head")
			else
				warn("[OutfitMockTest] Head part missing face decal - this may look incorrect")
			end
		end

		-- Now remove the old face decal from old part
		for _, child in ipairs(oldPart:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end

	-- ========================================
	-- COMPREHENSIVE PHYSICS PRESERVATION
	-- ========================================
	print(string.format("[OutfitMockTest] Replacing %s", partName))

	-- Basic physics properties
	clonedPart.Anchored = oldPart.Anchored
	clonedPart.CanCollide = oldPart.CanCollide
	clonedPart.Massless = oldPart.Massless

	-- Assembly properties (CRITICAL for preventing "brick by brick" death)
	pcall(function()
		clonedPart.RootPriority = oldPart.RootPriority
		clonedPart.AssemblyLinearVelocity = oldPart.AssemblyLinearVelocity
		clonedPart.AssemblyAngularVelocity = oldPart.AssemblyAngularVelocity
		clonedPart.AssemblyMass = oldPart.AssemblyMass
		clonedPart.AssemblyCenterOfMass = oldPart.AssemblyCenterOfMass
	end)

	-- Custom physical properties (material friction, elasticity, etc.)
	if oldPart.CustomPhysicalProperties then
		clonedPart.CustomPhysicalProperties = oldPart.CustomPhysicalProperties
		print(string.format("[OutfitMockTest] Copied CustomPhysicalProperties for %s", partName))
	end

	-- Collision group (important for gameplay physics)
	local success, err = pcall(function()
		clonedPart.CollisionGroup = oldPart.CollisionGroup
	end)
	if not success then
		warn(string.format("[OutfitMockTest] Failed to copy CollisionGroup for %s: %s", partName, tostring(err)))
	end

	-- DEBUG: Log physics state
	print(
		string.format(
			"[OutfitMockTest] %s Physics - Anchored:%s CanCollide:%s Massless:%s RootPriority:%d",
			partName,
			tostring(clonedPart.Anchored),
			tostring(clonedPart.CanCollide),
			tostring(clonedPart.Massless),
			clonedPart.RootPriority or 0
		)
	)

	-- DEBUG: Log velocity
	local vel = clonedPart.AssemblyLinearVelocity
	if vel and vel.Magnitude > 0.01 then
		print(string.format("[OutfitMockTest] %s has velocity: %.2f studs/sec", partName, vel.Magnitude))
	end

	-- CRITICAL: Parent the new part BEFORE destroying the old one to maintain physics assembly
	-- This ensures Motor6D connections transfer seamlessly without breaking the character
	clonedPart.Parent = character
	oldPart:Destroy()

	print(string.format("[OutfitMockTest] Replaced %s successfully", partName))
end

function OutfitMockTest:_applyClothing(character: Model, outfitModel: Model)
	local existingShirt = character:FindFirstChildOfClass("Shirt")
	local existingPants = character:FindFirstChildOfClass("Pants")

	if existingShirt then
		existingShirt:Destroy()
	end
	if existingPants then
		existingPants:Destroy()
	end

	local outfitShirt = outfitModel:FindFirstChildOfClass("Shirt")
	local outfitPants = outfitModel:FindFirstChildOfClass("Pants")

	if outfitShirt then
		outfitShirt:Clone().Parent = character
	end

	if outfitPants then
		outfitPants:Clone().Parent = character
	end
end

function OutfitMockTest:_applyBodyColors(character: Model, outfitModel: Model)
	local outfitBodyColors = outfitModel:FindFirstChildOfClass("BodyColors")
	if not outfitBodyColors then
		return
	end

	local existingBodyColors = character:FindFirstChildOfClass("BodyColors")
	if existingBodyColors then
		existingBodyColors:Destroy()
	end

	outfitBodyColors:Clone().Parent = character
end

function OutfitMockTest:_applyAccessories(character: Model, outfitModel: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end

	for _, child in ipairs(outfitModel:GetChildren()) do
		if child:IsA("Accessory") then
			local accessoryClone = child:Clone()
			humanoid:AddAccessory(accessoryClone)
		end
	end
end

-- Legacy Start function for automatic outfit cycling test
function OutfitMockTest:Start()
	if not ENABLE_OUTFIT_TEST then
		print("[OutfitMockTest] Disabled - set ENABLE_OUTFIT_TEST to true to enable")
		return
	end

	print("[OutfitMockTest] Starting outfit cycling test...")

	Knit.OnStart():await()
	local OutfitService = Knit.GetService("OutfitService")

	-- Test function for a single player
	local function startCyclingForPlayer(player: Player)
		local currentIndex = 1
		local showingOutfit = false

		task.spawn(function()
			task.wait(2)

			local data = OutfitService.outfitRepository:GetPlayerData(player)
			if data then
				for _, outfitId in ipairs(OUTFIT_IDS) do
					if not table.find(data.Outfits.Unlocked, outfitId) then
						table.insert(data.Outfits.Unlocked, outfitId)
					end
				end
				print(`[OutfitMockTest] Unlocked {#OUTFIT_IDS} outfits for {player.Name}`)
			end

			while player.Parent and ENABLE_OUTFIT_TEST do
				if not showingOutfit then
					local outfitId = OUTFIT_IDS[currentIndex]
					print(`[OutfitMockTest] Equipping outfit {outfitId} for {player.Name}`)
					local result = OutfitService:Equip(player, outfitId)

					if result.type == "SUCCESS" then
						print(`[OutfitMockTest] ✓ Successfully equipped outfit {outfitId}`)
					else
						warn(`[OutfitMockTest] ✗ Failed to equip outfit {outfitId}: {result.text}`)
					end

					showingOutfit = true
				else
					print(`[OutfitMockTest] Restoring to original appearance for {player.Name}`)
					local result = OutfitService:Equip(player, 0)

					if result.type == "SUCCESS" then
						print(`[OutfitMockTest] ✓ Successfully restored original appearance`)
					else
						warn(`[OutfitMockTest] ✗ Failed to restore original: {result.text}`)
					end

					showingOutfit = false
					currentIndex = currentIndex + 1
					if currentIndex > #OUTFIT_IDS then
						currentIndex = 1
					end
				end

				task.wait(CYCLE_INTERVAL)
			end
		end)
	end

	-- Start cycling for all current players
	for _, player in ipairs(Players:GetPlayers()) do
		startCyclingForPlayer(player)
	end

	-- Start cycling for new players
	Players.PlayerAdded:Connect(startCyclingForPlayer)

	print(
		"[OutfitMockTest] Test initialized! Alternating between outfits and original every",
		CYCLE_INTERVAL,
		"seconds"
	)
end

return OutfitMockTest
