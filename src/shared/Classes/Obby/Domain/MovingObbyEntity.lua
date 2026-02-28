local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

local MovingObbyEntity = {}
MovingObbyEntity.__index = MovingObbyEntity

--[[ Debug MODE ]]
local DEBUG_DISABLE_ALL_MOVEMENT = false

function MovingObbyEntity.new(id: string, basePart: BasePart | Model)
	local self = setmetatable({}, MovingObbyEntity)

	self.Id = id
	self.BasePart = basePart

	if basePart:IsA("Model") then
		self.OriginalCFrame = basePart:GetPivot()
	else
		self.OriginalCFrame = basePart.CFrame
	end

	self.Speed = 2
	self.Height = 5
	self.TimeOffset = 0

	self:SetAttribute(ObbyData.ObbyType.MOVING)

	return self
end

function MovingObbyEntity:Update(deltaTime: number)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return
	end

	local time = os.clock() + self.TimeOffset
	local yOffset = math.sin(time * self.Speed) * self.Height

	if self.BasePart:IsA("Model") then
		self.BasePart:PivotTo(self.OriginalCFrame + Vector3.new(0, yOffset, 0))
	else
		self.BasePart.CFrame = self.OriginalCFrame + Vector3.new(0, yOffset, 0)
	end

	return false
end

function MovingObbyEntity:SetAttribute(type: number)
	if self.BasePart:GetAttribute("ObbyType") == nil then
		self.BasePart:SetAttribute("ObbyType", type)
	end
end

function MovingObbyEntity:SetRandomTimers()
	self.TimeOffset = math.random() * math.pi * 2
end

return MovingObbyEntity
