-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Spawnable Class
local Spawnable = {}
Spawnable.__index = Spawnable

-- Collections
local Assets = ReplicatedStorage:WaitForChild("Assets")

function Spawnable.new(templateName: string, position: Vector3)
	local self = setmetatable({}, Spawnable)
	self.TemplateName = templateName
	self.Position = position
	self.Instance = nil
	return self
end

function Spawnable:Spawn()
	local template = Assets:WaitForChild(self.TemplateName)

	if not template then
		warn("Template not found:", self.TemplateName)
		for _, child in ipairs(Assets:GetChildren()) do
			print(" Available Assets ", child.Name)
		end
		return nil
	end

	local clone = template:Clone()
	clone.Position = self.Position or Vector3.new(0, 0, 0)
	clone.Parent = Workspace

	self.Instance = clone
	-- print(`[Spawnable] Spawned {self.TemplateName} at {tostring(self.Position)}`)
	return clone
end

function Spawnable:Destroy()
	if self.Instance then
		self.Instance:Destroy()
		self.Instance = nil
	end
end

return Spawnable
