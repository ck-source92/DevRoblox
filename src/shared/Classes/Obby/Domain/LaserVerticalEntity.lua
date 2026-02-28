local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

local LaserVerticalEntity = {}
LaserVerticalEntity.__index = LaserVerticalEntity

local DEBUG_DISABLE_ALL_MOVEMENT = false

function LaserVerticalEntity.new(id: string, basePart: BasePart | Model, minPos: number?, maxPos: number?)
	local self = setmetatable({}, LaserVerticalEntity)

	self.Id = id
	self.BasePart = basePart
	self.OriginalCFrame = if basePart:IsA("Model") then basePart:GetPivot() else basePart.CFrame

	--[[TODO: ADJUST POSITION OBBY IN REAL GAME]]
	self.MinPos = minPos or 2558.58 -- left part
	self.MaxPos = maxPos or 2542.68 -- right part

	self.Speed = 2
	self.TimeOffset = 0

	local parent = basePart.Parent
	if parent then
		if parent.Name == "LaserL" then
			self.TimeOffset = -math.pi / 2 / self.Speed
		elseif parent.Name == "LaserR" then
			self.TimeOffset = math.pi / 2 / self.Speed
		end
	end

	self:SetAttribute(ObbyData.ObbyType.LASER_VERTICAL)

	return self
end

function LaserVerticalEntity:Update(deltaTime: number)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return
	end

	local time = os.clock() + self.TimeOffset

	local range = (self.MaxPos - self.MinPos) / 2
	local center = (self.MinPos + self.MaxPos) / 2
	local xOffset = center + (math.sin(time * self.Speed) * range)

	if self.BasePart:IsA("Model") then
		local originalPos = self.OriginalCFrame.Position
		self.BasePart:PivotTo(CFrame.new(xOffset, originalPos.Y, originalPos.Z) * (self.OriginalCFrame - originalPos))
	else
		local originalPos = self.OriginalCFrame.Position
		self.BasePart.CFrame = CFrame.new(xOffset, originalPos.Y, originalPos.Z) * (self.OriginalCFrame - originalPos)
	end

	return false
end

function LaserVerticalEntity:SetAttribute(type: number)
	if self.BasePart:GetAttribute("ObbyType") == nil then
		self.BasePart:SetAttribute("ObbyType", type)
	end
end

function LaserVerticalEntity:SetRandomTimers()
	local parent = self.BasePart

	if parent and parent.Name == "LaserL" then
		self.TimeOffset = -math.pi / 2 / self.Speed
		return
	end

	if parent and parent.Name == "LaserR" then
		self.TimeOffset = math.pi / 2 / self.Speed
		return
	end

	self.TimeOffset = math.random() * math.pi * 2
end

return LaserVerticalEntity
