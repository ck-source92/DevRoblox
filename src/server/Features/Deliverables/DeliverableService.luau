--!strict
-- Features/Deliverables/DeliverableService.luau
-- Infrastructure logic for Deliverables (formerly PushObject).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local DeliverableDomain = require(ReplicatedStorage.Shared.Features.Deliverables.Domain.Deliverable)

local BOX_TAG = "PushBox"
local DETECTOR_TAG = "BoxDetector"
local SCORE_PER_BOX = 10

local DeliverableService = Knit.CreateService({
	Name = "DeliverableService",
	Client = {},
	_deliverables = {}, -- [BasePart] = DeliverableDomain
	_constraints = {},
})

function DeliverableService:KnitInit()
	-- Initial setup
end

function DeliverableService:KnitStart()
	-- Bind objects
	for _, inst in ipairs(CollectionService:GetTagged(BOX_TAG)) do
		if inst:IsA("BasePart") then
			self:_bindDeliverable(inst)
		end
	end

	CollectionService:GetInstanceAddedSignal(BOX_TAG):Connect(function(inst)
		if inst:IsA("BasePart") then
			self:_bindDeliverable(inst)
		end
	end)

	-- Detectors
	for _, inst in ipairs(CollectionService:GetTagged(DETECTOR_TAG)) do
		if inst:IsA("BasePart") then
			self:_bindDetector(inst)
		end
	end
end

function DeliverableService:_bindDeliverable(box: BasePart)
	local domain = DeliverableDomain.new()
	self._deliverables[box] = domain

	box.Touched:Connect(function(hit)
		if domain.State.IsScored then
			return
		end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			if domain:AssignOwner(player) then
				self:_attachToPlayer(box, player)
			end
		end
	end)
end

function DeliverableService:_attachToPlayer(box: BasePart, player: Player)
	if self._constraints[box] then
		return
	end

	-- Physics logic (simplified AlignPosition/Orientation)
	box.Anchored = false
	pcall(function()
		box:SetNetworkOwner(player)
	end)

	-- Note: In a full refactor, we would extract the constraint logic
	-- into a Physics utility or Infrastructure class.
	local alignPos = Instance.new("AlignPosition")
	-- ... (Implementation details from original PushObjectServices)
	self._constraints[box] = { alignPos = alignPos }
end

function DeliverableService:_bindDetector(detector: BasePart)
	detector.Touched:Connect(function(hit)
		local domain = self._deliverables[hit]
		if domain and domain.State.Owner then
			self:_onDelivered(hit, detector, domain)
		end
	end)
end

function DeliverableService:_onDelivered(box: BasePart, detector: BasePart, domain: any)
	local player = domain.State.Owner
	domain:MarkAsScored()

	-- Award Points via PointsService
	local PointsService = Knit.GetService("PointsService")
	PointsService:AddPoints(player, SCORE_PER_BOX)

	box:Destroy()
end

return DeliverableService
