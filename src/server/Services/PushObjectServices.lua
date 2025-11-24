local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Knit = require(game.ReplicatedStorage.Packages.Knit)

local PointsService = nil

local BOX_TAG = "PushBox"
local DETECTOR_TAG = "BoxDetector"
local SCORE_PER_BOX = 10
local PUSH_MAX_DISTANCE = 10 -- how far in front of player we search

local PushObjectServices = Knit.CreateService({
	Name = "PushObjectServices",
	Client = {},

	_boxOwner = {}, -- [BasePart] = Player
	_playerBox = {}, -- [Player] = BasePart
	_playerBoxes = {}, -- [Player] = { [BasePart] = true, ... }
	_boxScored = {}, -- [BasePart] = boolean
	_boxTouchedConns = {}, -- [BasePart] = RBXScriptConnection
	_detectorConns = {}, -- [BasePart] = RBXScriptConnection
	_primaryBoxByPlayer = {},
	_boxConstraints = {},
})

function PushObjectServices:KnitInit()
	PointsService = Knit.GetService("PointsService")
end

function PushObjectServices:KnitStart()
	print("[Push Object Service Started]")

	-- Bind existing boxes
	for _, inst in ipairs(CollectionService:GetTagged(BOX_TAG)) do
		if inst:IsA("BasePart") then
			self:_bindBox(inst)
		end
	end

	-- Bind future boxes
	CollectionService:GetInstanceAddedSignal(BOX_TAG):Connect(function(inst)
		if inst:IsA("BasePart") then
			self:_bindBox(inst)
		end
	end)

	-- Bind existing detectors
	for _, inst in ipairs(CollectionService:GetTagged(DETECTOR_TAG)) do
		if inst:IsA("BasePart") then
			self:_bindDetector(inst)
		end
	end

	-- Bind future detectors
	CollectionService:GetInstanceAddedSignal(DETECTOR_TAG):Connect(function(inst)
		if inst:IsA("BasePart") then
			self:_bindDetector(inst)
		end
	end)
	print("[Push Object Service Finished]")
end

function PushObjectServices:_attachPrimaryBoxToPlayer(box: BasePart, player: Player)
	-- Don’t double-attach
	if self._boxConstraints[box] then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[PushObjectService] _attachPrimaryBoxToPlayer: no HumanoidRootPart for", player.Name)
		return
	end

	-- Reusable attachment on the player’s HRP
	local hrpAttachment = hrp:FindFirstChild("PushBox_Attachment")
	if not hrpAttachment then
		hrpAttachment = Instance.new("Attachment")
		hrpAttachment.Name = "PushBox_Attachment"
		hrpAttachment.Parent = hrp

		-- 4 studs in front of the player (tweak to taste)
		hrpAttachment.Position = Vector3.new(0, 0, -4)
	end

	-- Make sure box can move
	if box.Anchored then
		box.Anchored = false
	end

	-- Attachment on the box
	local boxAttachment = Instance.new("Attachment")
	boxAttachment.Name = "PushBox_Attachment"
	boxAttachment.Parent = box

	-- Position follower
	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = "PushBox_AlignPosition"
	alignPos.ApplyAtCenterOfMass = true
	alignPos.Responsiveness = 10 -- how fast it follows
	alignPos.MaxForce = 100000 -- tweak if too weak/too strong
	alignPos.Attachment0 = boxAttachment
	alignPos.Attachment1 = hrpAttachment
	alignPos.Parent = box

	-- Orientation follower
	local alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "PushBox_AlignOrientation"
	alignOri.Responsiveness = 10
	alignOri.MaxTorque = 100000
	alignOri.Attachment0 = boxAttachment
	alignOri.Attachment1 = hrpAttachment
	alignOri.Parent = box

	-- Optional: let this player own simulation for smoother movement
	pcall(function()
		box:SetNetworkOwner(player)
	end)

	self._boxConstraints[box] = {
		alignPos = alignPos,
		alignOri = alignOri,
		attachment = boxAttachment,
	}
	self._primaryBoxByPlayer[player] = box

	print(("[PushObjectService] Attached primary box %s to %s"):format(box.Name, player.Name))
end

function PushObjectServices:_detachPrimaryBox(box: BasePart, player: Player?)
	local data = self._boxConstraints[box]
	if data then
		if data.alignPos then
			data.alignPos:Destroy()
		end
		if data.alignOri then
			data.alignOri:Destroy()
		end
		if data.attachment then
			data.attachment:Destroy()
		end
		self._boxConstraints[box] = nil
	end

	if player and self._primaryBoxByPlayer[player] == box then
		self._primaryBoxByPlayer[player] = nil
	else
		-- Fallback, in case we didn’t pass player
		for p, b in pairs(self._primaryBoxByPlayer) do
			if b == box then
				self._primaryBoxByPlayer[p] = nil
				break
			end
		end
	end

	print(("[PushObjectService] Detached primary box %s"):format(box.Name))
end

function PushObjectServices:_assignBoxToPlayer(box: BasePart, player: Players)
	if self._boxScored[box] or box:GetAttribute("HasScored") then
		print(("[PushObjectService] _assignBoxToPlayer: box %s already scored"):format(box.Name))
		return
	end

	local currentOwner = self._boxOwner[box]
	if currentOwner and currentOwner ~= player then
		print(
			("[PushObjectService] _assignBoxToPlayer: box %s already owned by %s, ignore %s"):format(
				box.Name,
				currentOwner.Name,
				player.Name
			)
		)
		return
	end

	self._boxOwner[box] = player
	self._playerBoxes[player] = self._playerBoxes[player] or {}
	self._playerBoxes[player][box] = true

	print(("[PushObjectService] %s now owns box %s"):format(player.Name, box.Name))

	-- NEW: if player has no primary box yet, attach this one
	if not self._primaryBoxByPlayer[player] then
		self:_attachPrimaryBoxToPlayer(box, player)
	end
end

function PushObjectServices:_clearBoxOwner(box: BasePart)
	local player = self._boxOwner[box]

	-- NEW: detach if this box was their primary
	if player and self._primaryBoxByPlayer[player] == box then
		self:_detachPrimaryBox(box, player)
	end

	if player then
		local set = self._playerBoxes[player]
		if set then
			set[box] = nil
			if not next(set) then
				self._playerBoxes[player] = nil
			end
		end

		print(("[PushObjectService] Clear owner: %s no longer owns box %s"):format(player.Name, box.Name))
	end

	self._boxOwner[box] = nil
end

-- If one box has owner and the other doesn’t, copy owner (chain)
function PushObjectServices:_handleBoxBoxTouch(boxA: BasePart, boxB: BasePart)
	if boxA == boxB then
		return
	end

	if self._boxScored[boxA] or boxA:GetAttribute("HasScored") then
		return
	end
	if self._boxScored[boxB] or boxB:GetAttribute("HasScored") then
		return
	end

	local ownerA = self._boxOwner[boxA]
	local ownerB = self._boxOwner[boxB]

	if ownerA and not ownerB then
		self:_assignBoxToPlayer(boxB, ownerA)
		print(
			("[PushObjectService] Chain: box %s inherited owner %s from box %s"):format(
				boxB.Name,
				ownerA.Name,
				boxA.Name
			)
		)
	elseif ownerB and not ownerA then
		self:_assignBoxToPlayer(boxA, ownerB)
		print(
			("[PushObjectService] Chain: box %s inherited owner %s from box %s"):format(
				boxA.Name,
				ownerB.Name,
				boxB.Name
			)
		)
	else
		-- both owned or both nil → do nothing
	end
end

function PushObjectServices:_handlePlayerTouchBox(player: Player, box: BasePart)
	if self._boxScored[box] or box:GetAttribute("HasScored") then
		print(("[PushObjectService] Player %s touched scored box %s, ignored"):format(player.Name, box.Name))
		return
	end

	local currentOwner = self._boxOwner[box]

	-- Already owned by same player
	if currentOwner == player then
		return
	end

	-- Owned by someone else
	if currentOwner and currentOwner ~= player then
		print(
			("[PushObjectService] Box %s already owned by %s; ignore %s"):format(
				box.Name,
				currentOwner.Name,
				player.Name
			)
		)
		return
	end

	-- No owner → give to this player
	self:_assignBoxToPlayer(box, player)
end

function PushObjectServices:_bindBox(box: BasePart)
	if self._boxTouchedConns[box] then
		return
	end

	print("[PushObjectServices] Binding box:", box:GetFullName())

	local conn = box.Touched:Connect(function(hit)
		-- If box already scored, ignore all touches
		if self._boxScored[box] or box:GetAttribute("HasScored") then
			return
		end

		-- 1) Box ↔ Box chain touch
		if hit:IsA("BasePart") and CollectionService:HasTag(hit, BOX_TAG) and hit ~= box then
			self:_handleBoxBoxTouch(box, hit)
			return
		end

		-- 2) Player ↔ Box touch
		local character = hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		self:_handlePlayerTouchBox(player, box)
	end)

	self._boxTouchedConns[box] = conn

	box.AncestryChanged:Connect(function(_, parent)
		if not parent then
			print("[PushObjectServices] Box removed from game, cleaning up:", box:GetFullName())
			local c = self._boxTouchedConns[box]
			if c then
				c:Disconnect()
			end
			self._boxTouchedConns[box] = nil

			self:_clearBoxOwner(box)
			self._boxScored[box] = nil
		end
	end)
end

function PushObjectServices:_bindDetector(detector: BasePart)
	if self._detectorConns[detector] then
		return
	end

	print("[PushObjectServices] Binding detector:", detector:GetFullName())

	local conn = detector.Touched:Connect(function(hit)
		if not hit:IsA("BasePart") then
			return
		end

		-- Expect the box itself to be tagged BOX_TAG.
		-- If your tag is on a Model, adjust this part to search ancestors.
		if not CollectionService:HasTag(hit, BOX_TAG) then
			return
		end

		self:_onBoxEnterDetector(hit, detector)
	end)

	self._detectorConns[detector] = conn

	detector.AncestryChanged:Connect(function(_, parent)
		if not parent then
			print("[PushObjectServices] Detector removed from game, cleaning up:", detector:GetFullName())
			local c = self._detectorConns[detector]
			if c then
				c:Disconnect()
			end
			self._detectorConns[detector] = nil
		end
	end)
end

function PushObjectServices:_onBoxEnterDetector(box: BasePart, detector: BasePart)
	print(("[PushObjectServices] Box %s touched detector %s"):format(box.Name, detector.Name))

	if self._boxScored[box] or box:GetAttribute("HasScored") then
		print(("[PushObjectServices] Box %s already scored previously, ignore"):format(box.Name))
		return
	end

	local player = self._boxOwner[box]
	if not player then
		warn(("[PushObjectServices] Box %s has no owner when entering detector"):format(box.Name))
		return
	end

	-- Mark as scored BEFORE giving points
	self._boxScored[box] = true
	box:SetAttribute("HasScored", true)

	print(("[PushObjectServices] Awarding %d points to %s for box %s"):format(SCORE_PER_BOX, player.Name, box.Name))

	PointsService:AddPoints(player, SCORE_PER_BOX)

	-- Clear the ownership (box is "finished")
	self:_clearBoxOwner(box)
end

function PushObjectServices:StopPushingBox(player: Player)
	local boxes = self._playerBoxes[player]
	if not boxes then
		print(("[PushObjectServices] StopPushingBox: %s is not pushing any boxes"):format(player.Name))
		return
	end

	local count = 0
	for box, _ in pairs(boxes) do
		self:_clearBoxOwner(box)
		count += 1
	end

	self._playerBoxes[player] = nil

	print(("[PushObjectServices] %s stopped pushing %d boxes"):format(player.Name, count))
end

-- Called from client when player presses E
function PushObjectServices.Client:RequestStopPushing(player: Player)
	self.Server:StopPushingBox(player)
end

return PushObjectServices
