local Players = game:GetService("Players")
local ObbyData = require(game:GetService("ReplicatedStorage").Shared.Classes.Obby.Domain.ObbyData)

local ObbyEntity = {}
ObbyEntity.__index = ObbyEntity

--[[ Debug MODE ]]
local DEBUG_DISABLE_ALL_MOVEMENT = false

-- Helper function to get all BaseParts from either a BasePart or Model
local function GetAllParts(instance: BasePart | Model): { BasePart }
	if instance:IsA("BasePart") then
		return { instance }
	elseif instance:IsA("Model") then
		local parts = {}
		for _, descendant in ipairs(instance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		return parts
	end
	return {}
end

function ObbyEntity.new(id: string, basePart: BasePart | Model)
	local self = setmetatable({}, ObbyEntity)

	self.Id = id
	self.BasePart = basePart
	self.Parts = GetAllParts(basePart) -- All parts to manipulate
	self.State = ObbyData.ObbyState.VISIBLE
	self.CurrentTimer = 0
	self.CooldownDuration = 0
	self.ActiveDuration = 0
	self._lastTouch = 0
	self:SetAttribute(ObbyData.ObbyType.STATIC)

	-- Store original properties for each part
	self.OriginalProperties = {}
	for _, part in ipairs(self.Parts) do
		self.OriginalProperties[part] = {
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
		}
	end

	-- Set up Touched event for all parts
	for _, part in ipairs(self.Parts) do
		part.Touched:Connect(function(hit)
			self:OnTouched(hit)
		end)
	end

	return self
end

function ObbyEntity:OnTouched(hit: BasePart)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return
	end

	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then
		return
	end

	if os.time() - self._lastTouch < 1 then
		return
	end
	self._lastTouch = os.time()

	if self.State == ObbyData.ObbyState.VISIBLE then
		self.CurrentTimer = math.max(0, self.CurrentTimer + 2)
		print("[ObbyEntity] Timer extended for", self.Id)
	end
end

function ObbyEntity:SetRandomTimers()
	self.CooldownDuration = math.random(5, 8)
	self.ActiveDuration = math.random(2, 5)
	self.CurrentTimer = 0
end

function ObbyEntity:Update(deltaTime: number)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return false
	end

	self.CurrentTimer = self.CurrentTimer + deltaTime

	local duration = if self.State == ObbyData.ObbyState.VISIBLE then self.CooldownDuration else self.ActiveDuration

	if self.CurrentTimer >= duration then
		return true
	end

	return false
end

function ObbyEntity:Hide()
	self.State = ObbyData.ObbyState.INVISIBLE
	for _, part in ipairs(self.Parts) do
		part.Transparency = 1
		part.CanCollide = false
	end
	self.CurrentTimer = 0
end

function ObbyEntity:Show()
	self.State = ObbyData.ObbyState.VISIBLE
	for _, part in ipairs(self.Parts) do
		part.Transparency = self.OriginalProperties[part].Transparency
		part.CanCollide = self.OriginalProperties[part].CanCollide
	end
	self.CurrentTimer = 0
end

function ObbyEntity:Reset()
	self.State = ObbyData.ObbyState.VISIBLE
	self:SetRandomTimers()
end

function ObbyEntity:SetAttribute(type: number)
	-- Set attribute on the root instance (BasePart or Model)
	if self.BasePart:GetAttribute("ObbyType") == nil then
		self.BasePart:SetAttribute("ObbyType", type)
	end
end

return ObbyEntity
