local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Knit = require(game.ReplicatedStorage.Packages.Knit)

local PointsService = nil

local BOX_TAG = "PushBox"
local DETECTOR_TAG = "BoxDetector"
local SCORE_PER_BOX = 10

local PushObjectServices = Knit.CreateService({
	Name = "PushObjectServices",
	Client = {},

	_lastPusherByBox = {}, -- [BasePart] = Player
	_boxConnections = {}, -- [BasePart] = RBXScriptConnection
	_detectorConnections = {}, -- [BasePart] = RBXScriptConnection

	_boxOwner = {}, -- [BasePart] = Player
	_playerBox = {}, -- [Player] = BasePart
	_boxScored = {}, -- [BasePart] = boolean
	_boxTouchedConns = {}, -- [BasePart] = RBXScriptConnection
	_detectorConns = {}, -- [BasePart] = RBXScriptConnection
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

function PushObjectServices:_clearBoxOwner(box: BasePart)
	local player = self._boxOwner[box]
	if player then
		if self._playerBox[player] == box then
			self._playerBox[player] = nil
		end
		print(("[PushObjectServices] Clearing ownership: %s no longer owns box %s"):format(player.Name, box.Name))
	end
	self._boxOwner[box] = nil
end

function PushObjectServices:_bindBox(box: BasePart)
	if self._boxTouchedConns[box] then
		return
	end

	print("[PushObjectServices] Binding box:", box:GetFullName())

	local conn = box.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		if self._boxScored[box] or box:GetAttribute("HasScored") then
			print(("[PushObjectServices] Box %s already scored; ignore touch from %s"):format(box.Name, player.Name))
			return
		end

		-- Already has an owner?
		if self._boxOwner[box] then
			if self._boxOwner[box] ~= player then
				print(
					("[PushObjectServices] Box %s already owned by %s; ignore %s"):format(
						box.Name,
						self._boxOwner[box].Name,
						player.Name
					)
				)
			end
			return
		end

		-- Player already pushing another box?
		if self._playerBox[player] and self._playerBox[player] ~= box then
			print(
				("[PushObjectServices] %s is already pushing box %s; ignore new box %s"):format(
					player.Name,
					self._playerBox[player].Name,
					box.Name
				)
			)
			return
		end

		-- Assign ownership
		self._boxOwner[box] = player
		self._playerBox[player] = box

		print(("[PushObjectServices] %s is now pushing box %s"):format(player.Name, box.Name))
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

	-- 1. Make sure this box can only score once
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
	local box = self._playerBox[player]
	if not box then
		print(("[PushObjectServices] StopPushingBox: %s is not pushing any box"):format(player.Name))
		return
	end

	print(("[PushObjectServices] StopPushingBox: %s stopped pushing box %s manually"):format(player.Name, box.Name))

	self:_clearBoxOwner(box)
end

-- Called from client when player presses E
function PushObjectServices.Client:RequestStopPushing(player: Player)
	self.Server:StopPushingBox(player)
end

return PushObjectServices
