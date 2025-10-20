local Spawnable = {}
Spawnable.__index = Spawnable

function Spawnable.new(templateName, position)
	local self = setmetatable({}, Spawnable)
	self.TemplateName = templateName
	self.Position = position
	self.Instance = nil
	return self
end

function Spawnable:Spawn()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local assets = ReplicatedStorage:WaitForChild("Assets")
	local template = assets:FindFirstChild(self.TemplateName)

	if not template then
		warn("Template not found:", self.TemplateName)
		return
	end

	self.Instance = template:Clone()
	self.Instance.Parent = workspace
end

function Spawnable:Destroy()
	if self.Instance then
		self.Instance:Destroy()
		self.Instance = nil
	end
end
return Spawnable
