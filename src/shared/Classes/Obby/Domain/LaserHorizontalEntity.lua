local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

local LaserHorizontalEntity = {}
LaserHorizontalEntity.__index = LaserHorizontalEntity

local DEBUG_DISABLE_ALL_MOVEMENT = false

function LaserHorizontalEntity.new(id: string, basePart: BasePart | Model, minPos: number?, maxPos: number?)
	local self = setmetatable({}, LaserHorizontalEntity)

	self.Id = id
	self.BasePart = basePart
	self.OriginalCFrame = if basePart:IsA("Model") then basePart:GetPivot() else basePart.CFrame

	--[[TODO: ADJUST POSITION OBBY IN REAL GAME]]
	self.MinPos = minPos or 1.3 -- boundaries bottom part
	self.MaxPos = maxPos or 18.5 -- boundaries top part

	self.Speed = 0.8
	self.TimeOffset = 0

	local parent = basePart.Parent
	if parent then
		if parent.Name == "LaserT" then
			self.TimeOffset = math.pi / 2 / self.Speed
		elseif parent.Name == "LaserB" then
			self.TimeOffset = -math.pi / 2 / self.Speed
		end
	end

	self:SetAttribute(ObbyData.ObbyType.LASER_HORIZONTAL)

	return self
end

function LaserHorizontalEntity:Update(deltaTime: number)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return
	end

	local time = os.clock() + self.TimeOffset

	local range = (self.MaxPos - self.MinPos) / 2
	local center = (self.MinPos + self.MaxPos) / 2
	local yOffset = center + (math.sin(time * self.Speed) * range)

	if self.BasePart:IsA("Model") then
		local originalPos = self.OriginalCFrame.Position
		self.BasePart:PivotTo(CFrame.new(originalPos.X, yOffset, originalPos.Z) * (self.OriginalCFrame - originalPos))
	else
		local originalPos = self.OriginalCFrame.Position
		self.BasePart.CFrame = CFrame.new(originalPos.X, yOffset, originalPos.Z) * (self.OriginalCFrame - originalPos)
	end

	return false
end

function LaserHorizontalEntity:SetAttribute(type: number)
	if self.BasePart:GetAttribute("ObbyType") == nil then
		self.BasePart:SetAttribute("ObbyType", type)
	end
end

function LaserHorizontalEntity:SetRandomTimers()
	local parent = self.BasePart

	if parent and parent.Name == "LaserT" then
		self.TimeOffset = math.pi / 2 / self.Speed
		return
	end

	if parent and parent.Name == "LaserB" then
		self.TimeOffset = -math.pi / 2 / self.Speed
		return
	end

	self.TimeOffset = math.random() * math.pi * 2
end

return LaserHorizontalEntity
