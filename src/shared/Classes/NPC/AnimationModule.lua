-- AnimationModule.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationData = require(ReplicatedStorage.Shared.Helpers.AnimationModule.AnimationData)

local AnimationModule = {}
AnimationModule.__index = AnimationModule

-- 🔹 Simple priority aliases
local PriorityMap = {
	Idle = Enum.AnimationPriority.Idle,
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
	Action2 = Enum.AnimationPriority.Action2,
}

-- =====================================================
-- CONSTRUCTOR
-- =====================================================
function AnimationModule.new()
	local self = setmetatable({}, AnimationModule)

	self.Character = nil
	self.Humanoid = nil
	self.Animator = nil

	self.LoadedTracks = {}

	self.PlayingTracks = {}

	return self
end

-- =====================================================
-- LOAD CHARACTER
-- =====================================================
function AnimationModule:LoadCharacter(character)
	self.Character = character
	self.Humanoid = character:WaitForChild("Humanoid")

	self.Animator = self.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", self.Humanoid)

	self.LoadedTracks = {}
	self.PlayingTracks = {}

	for category, animations in pairs(AnimationData) do
		self.LoadedTracks[category] = {}

		for _, animData in ipairs(animations) do
			local animation = Instance.new("Animation")
			animation.Name = animData.name
			animation.AnimationId = animData.id

			local track = self.Animator:LoadAnimation(animation)
			track.Priority = animData.priority
			track.Looped = animData.isLooped

			self.LoadedTracks[category][animData.name] = track
		end
	end
end

-- =====================================================
-- INTERNAL HELPERS
-- =====================================================

-- Resolve string / enum priority
function AnimationModule:_ResolvePriority(priority)
	if typeof(priority) == "EnumItem" then
		return priority
	end

	if typeof(priority) == "string" then
		return PriorityMap[priority]
	end

	print("[AnimationModule] Invalid priority:", priority)

	return nil
end

-- Find animation track by name
function AnimationModule:_FindTrack(animationName)
	for _, category in pairs(self.LoadedTracks) do
		if category[animationName] then
			return category[animationName]
		end
	end
	return nil
end

function AnimationModule:HasAnimation(animationName)
	if type(animationName) ~= "string" then
		return false
	end

	return self:_FindTrack(animationName) ~= nil
end

-- Stop animation on a priority
function AnimationModule:_StopPriority(priority)
	local track = self.PlayingTracks[priority]
	if track then
		track:Stop()
		self.PlayingTracks[priority] = nil
	end
end

-- =====================================================
-- PUBLIC API
-- =====================================================

-- 🔹 Normal play (uses data priority)
function AnimationModule:Play(animationName)
	local track = self:_FindTrack(animationName)
	if not track then
		warn("Animation not found:", animationName)
		return
	end

	local priority = track.Priority
	self:_StopPriority(priority)

	track:Play()
	self.PlayingTracks[priority] = track
end

-- 🔹 Force play on specific priority (ignores data)
function AnimationModule:PlayAsPriority(animationName, priority)
	local track = self:_FindTrack(animationName)
	if not track then
		warn("Animation not found:", animationName)
		return
	end

	local resolvedPriority = self:_ResolvePriority(priority)
	if not resolvedPriority then
		warn("Invalid priority:", priority)
		return
	end

	self:_StopPriority(resolvedPriority)

	track.Priority = resolvedPriority
	track:Play()

	self.PlayingTracks[resolvedPriority] = track
end

-- 🔹 Play random animation from category (normal priority)
function AnimationModule:PlayRandomAnimation(categoryName)
	local category = self.LoadedTracks[categoryName]
	if not category then
		warn("Category not found:", categoryName)
		return
	end

	local list = {}
	for _, track in pairs(category) do
		table.insert(list, track)
	end

	if #list == 0 then
		return
	end

	local chosen = list[math.random(#list)]
	local priority = chosen.Priority

	self:_StopPriority(priority)

	chosen:Play()
	self.PlayingTracks[priority] = chosen
end

-- 🔹 Stop animations by priority (string or enum)
function AnimationModule:StopPriority(priority)
	local resolvedPriority = self:_ResolvePriority(priority)
	if not resolvedPriority then
		return
	end

	self:_StopPriority(resolvedPriority)
end

-- 🔹 Stop animation by name (any priority)
function AnimationModule:Stop(animationName)
	for priority, track in pairs(self.PlayingTracks) do
		if track and track.Name == animationName then
			track:Stop()
			self.PlayingTracks[priority] = nil
		end
	end
end

-- 🔹 Stop all animations
function AnimationModule:StopAll()
	for priority, track in pairs(self.PlayingTracks) do
		if track then
			track:Stop()
		end
	end
	self.PlayingTracks = {}
end

return AnimationModule
