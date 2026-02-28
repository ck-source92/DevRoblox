local ObbyData = require(game:GetService("ReplicatedStorage").Shared.Classes.Obby.Domain.ObbyData)

local SequenceObbyEntity = {}
SequenceObbyEntity.__index = SequenceObbyEntity

--[[ Debug MODE ]]
local DEBUG_DISABLE_ALL_MOVEMENT = false

-- Variative warning colors (shown 1 second before visible)
local WARNING_COLORS = {
	Color3.fromRGB(255, 255, 100), -- Yellow
}

function SequenceObbyEntity.new(id: string, folder: Folder)
	local self = setmetatable({}, SequenceObbyEntity)

	self.Id = id
	self.Folder = folder
	self.Parts = {}
	self.OriginalColors = {} -- Store original colors for restoration

	-- Find and sort parts/models by name (part1, model1, etc.)
	local children = folder:GetChildren()
	for _, child in ipairs(children) do
		if child:IsA("BasePart") or child:IsA("Model") then
			table.insert(self.Parts, child)
			-- Store original color
			self:StoreOriginalColor(child)
		end
	end

	table.sort(self.Parts, function(a, b)
		local numA = tonumber(string.match(a.Name, "%d+")) or 0
		local numB = tonumber(string.match(b.Name, "%d+")) or 0
		return numA < numB
	end)

	self.State = ObbyData.ObbyState.VISIBLE
	self.Timer = 0
	self.StepDuration = 1.6
	self.WarningTime = 1.0 -- Show warning color 1 second before visible
	self.WarningShown = false

	-- Dynamic Pattern Generation
	self:GeneratePatterns()

	self.PatternNames = { "CUSTOM", "WAVE" } --, "ALT" }
	self.CurrentPatternIndex = 1
	self.CurrentStepIndex = 1
	self.CyclesPerPattern = 2
	self.CurrentCycleCount = 0

	self:SetAttribute(ObbyData.ObbyType.SEQUENCE)
	self:UpdateVisibility()

	return self
end

function SequenceObbyEntity:StoreOriginalColor(inst)
	if inst:IsA("BasePart") then
		self.OriginalColors[inst] = inst.Color
	elseif inst:IsA("Model") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") then
				self.OriginalColors[child] = child.Color
			end
		end
	end
end

function SequenceObbyEntity:GeneratePatterns()
	local n = #self.Parts
	if n == 0 then
		return
	end

	local patterns = {}

	-- 1. WAVE (Window based)
	local windowSize = math.max(1, math.floor(n / 2) + 1)
	local wave = {}
	for i = 1, n do
		local step = {}
		for j = 0, windowSize - 1 do
			local idx = ((i + j - 1) % n) + 1
			table.insert(step, idx)
		end
		table.insert(wave, step)
	end
	patterns.WAVE = wave

	print("Pattern")
	print(wave)

	-- 2. REVERSE_WAVE
	local reverseWave = {}
	for i = n, 1, -1 do
		local step = {}
		for j = 0, windowSize - 1 do
			local idx = ((i - j - 1) % n) + 1
			table.insert(step, idx)
		end
		table.insert(reverseWave, step)
	end
	patterns.REVERSE_WAVE = reverseWave

	print(reverseWave)

	-- 3. ALT (Odd/Even)
	local altEven = {}
	local altOdd = {}
	for i = 1, n do
		if i % 2 == 0 then
			table.insert(altEven, i)
		else
			table.insert(altOdd, i)
		end
	end
	patterns.ALT = { altOdd, altEven }

	-- 4. PULSE (Outside-In)
	local pulse = {}
	local half = math.ceil(n / 2)
	for i = 1, half do
		local step = { i, n - i + 1 }
		table.insert(pulse, step)
	end
	for i = half - 1, 2, -1 do
		table.insert(pulse, { i, n - i + 1 })
	end
	patterns.PULSE = pulse

	local customPattern = {}

	-- Entry (wide but temporary)
	table.insert(customPattern, { 1, 2, 3, 4, 5, 6, 7 })
	-- Final walk
	table.insert(customPattern, { 2, 3, 5, 6 })
	-- Final walk
	table.insert(customPattern, { 2, 3, 4, 6, 7 })
	-- Final walk
	table.insert(customPattern, { 3, 4, 5, 6 })
	-- Final walk
	table.insert(customPattern, { 1, 5, 6, 7 })
	-- Final walk
	table.insert(customPattern, { 3, 4, 6, 7 })
	-- Final walk
	table.insert(customPattern, { 1, 2, 3, 4, 5 })
	-- Final walk
	table.insert(customPattern, { 1, 2, 3, 5, 7 })
	-- Final walk
	table.insert(customPattern, { 1, 2, 6, 7 })

	patterns.CUSTOM = customPattern

	self.Patterns = patterns
end

function SequenceObbyEntity:GetNextStepIndices()
	local patternName = self.PatternNames[self.CurrentPatternIndex]
	local pattern = self.Patterns[patternName]
	if not pattern then
		return {}
	end

	local nextStepIndex = self.CurrentStepIndex + 1
	if nextStepIndex > #pattern then
		nextStepIndex = 1
	end

	return pattern[nextStepIndex] or {}
end

function SequenceObbyEntity:UpdateWarningColors()
	local nextIndices = self:GetNextStepIndices()
	local nextIndicesSet = {}
	for _, idx in ipairs(nextIndices) do
		nextIndicesSet[idx] = true
	end

	local patternName = self.PatternNames[self.CurrentPatternIndex]
	local pattern = self.Patterns[patternName]
	local currentIndices = pattern and pattern[self.CurrentStepIndex] or {}
	local currentIndicesSet = {}
	for _, idx in ipairs(currentIndices) do
		currentIndicesSet[idx] = true
	end

	-- Apply warning colors to parts that will become INVISIBLE
	for i, inst in ipairs(self.Parts) do
		local willBeVisible = nextIndicesSet[i] == true
		local isCurrentlyVisible = currentIndicesSet[i] == true

		-- Show warning color for parts that ARE visible but will become invisible
		if isCurrentlyVisible and not willBeVisible then
			local warningColor = WARNING_COLORS[(i % #WARNING_COLORS) + 1]
			self:SetInstanceColor(inst, warningColor)
		end
	end
end

function SequenceObbyEntity:SetInstanceColor(inst, color)
	if inst:IsA("BasePart") then
		inst.Color = color
	elseif inst:IsA("Model") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Color = color
			end
		end
	end
end

function SequenceObbyEntity:RestoreOriginalColor(inst)
	if inst:IsA("BasePart") then
		if self.OriginalColors[inst] then
			inst.Color = self.OriginalColors[inst]
		end
	elseif inst:IsA("Model") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") and self.OriginalColors[child] then
				child.Color = self.OriginalColors[child]
			end
		end
	end
end

function SequenceObbyEntity:UpdateVisibility()
	local patternName = self.PatternNames[self.CurrentPatternIndex]
	local pattern = self.Patterns[patternName]
	if not pattern then
		return
	end

	local visibleIndicesList = pattern[self.CurrentStepIndex]

	local visibleIndices = {}
	if visibleIndicesList then
		for _, idx in ipairs(visibleIndicesList) do
			visibleIndices[idx] = true
		end
	end

	for i, inst in ipairs(self.Parts) do
		local isVisible = visibleIndices[i] == true
		self:RestoreOriginalColor(inst)
		self:SetInstanceVisibility(inst, isVisible)
	end

	self.WarningShown = false
end

function SequenceObbyEntity:SetInstanceVisibility(inst, isVisible, customTransparency)
	local transparency = customTransparency or (isVisible and 0 or 1)
	local canCollide = isVisible and (customTransparency == nil)

	if inst:IsA("BasePart") then
		inst.Transparency = transparency
		inst.CanCollide = canCollide
	elseif inst:IsA("Model") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = transparency
				child.CanCollide = canCollide
			end
		end
	end
end

function SequenceObbyEntity:Update(deltaTime: number)
	if DEBUG_DISABLE_ALL_MOVEMENT then
		return false
	end

	self.Timer = self.Timer + deltaTime

	local timeUntilStep = self.StepDuration - self.Timer
	if timeUntilStep <= self.WarningTime and not self.WarningShown then
		self.WarningShown = true
		self:UpdateWarningColors()
	end

	if self.Timer >= self.StepDuration then
		self.Timer = 0
		self:NextStep()
	end

	return false
end

function SequenceObbyEntity:NextStep()
	local patternName = self.PatternNames[self.CurrentPatternIndex]
	local pattern = self.Patterns[patternName]
	if not pattern then
		return
	end

	self.CurrentStepIndex = self.CurrentStepIndex + 1

	if self.CurrentStepIndex > #pattern then
		self.CurrentStepIndex = 1
		self.CurrentCycleCount = self.CurrentCycleCount + 1

		if self.CurrentCycleCount >= self.CyclesPerPattern then
			self.CurrentCycleCount = 0
			self.CurrentPatternIndex = self.CurrentPatternIndex + 1
			if self.CurrentPatternIndex > #self.PatternNames then
				self.CurrentPatternIndex = 1
			end
		end
	end

	self:UpdateVisibility()
end

function SequenceObbyEntity:SetAttribute(type: number)
	if self.Folder:GetAttribute("ObbyType") == nil then
		self.Folder:SetAttribute("ObbyType", type)
	end
end

function SequenceObbyEntity:SetRandomTimers() end

return SequenceObbyEntity
