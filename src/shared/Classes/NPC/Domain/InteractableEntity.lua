local InteractableEntity = {}
InteractableEntity.__index = InteractableEntity

export type InteractableEntity = {
	Model: Model,
	Position: Vector3,
	InteractType: string, -- "Destroy", "Repair", "Hacking", "Collect", "Scan"
	Map: string,
	IsOccupied: boolean,
}

function InteractableEntity.new(model: Model): InteractableEntity
	local self = setmetatable({}, InteractableEntity)

	self.Model = model
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	self.Position = primaryPart and primaryPart.Position or Vector3.zero
	self.InteractType = model:GetAttribute("InteractType") or "Scan"
	self.Map = model:GetAttribute("Map") or "Map1"

	self.IsOccupied = false

	return self
end

function InteractableEntity:SetOccupied(occupied: boolean)
	self.IsOccupied = occupied
end

function InteractableEntity:IsAvailable(): boolean
	return not self.IsOccupied and self.Model.Parent ~= nil
end

return InteractableEntity
