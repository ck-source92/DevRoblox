local InteractableUsecase = {}
InteractableUsecase.__index = InteractableUsecase

function InteractableUsecase.new(interactableRepository)
	local self = setmetatable({}, InteractableUsecase)

	self.repository = interactableRepository

	return self
end

-- Find nearest available interactable to NPC
function InteractableUsecase:FindNearestInteractable(npcPosition: Vector3, mapName: string, maxDistance: number?): any?
	local maxDist = maxDistance or 100
	local interactables = self.repository:GetInteractables(mapName)

	local nearest = nil
	local nearestDistance = math.huge

	for _, interactable in ipairs(interactables) do
		if interactable:IsAvailable() then
			local distance = (npcPosition - interactable.Position).Magnitude

			if distance < nearestDistance and distance <= maxDist then
				nearestDistance = distance
				nearest = interactable
			end
		end
	end

	return nearest
end

-- Start interaction with object
function InteractableUsecase:StartInteraction(npc: any, interactable: any)
	self.repository:SetOccupied(interactable, true)
	npc:SetState("Interacting")

	-- print("[InteractableUsecase] NPC", npc.Username, "started interacting with", interactable.InteractType)
end

-- End interaction
function InteractableUsecase:EndInteraction(npc: any, interactable: any)
	self.repository:SetOccupied(interactable, false)
	npc:SetState("Idle")

	-- print("[InteractableUsecase] NPC", npc.Username, "finished interacting")
end

-- Get random interactable for a map
function InteractableUsecase:GetRandomInteractable(mapName: string): any?
	return self.repository:GetRandomInteractable(mapName)
end

-- Avoid NPC stand on object
function InteractableUsecase:GetInteractionPosition(interactable: any): Vector3
	local objectPos = interactable.Position

	local angle = math.random() * math.pi * 2
	local distance = 6

	local offsetX = math.cos(angle) * distance
	local offsetZ = math.sin(angle) * distance

	return Vector3.new(objectPos.X + offsetX, objectPos.Y, objectPos.Z + offsetZ)
end

function InteractableUsecase:RequiresGear(interactable: any): boolean
	local interactType = interactable.InteractType
	if interactType == "Hacking" or interactType == "Repair" or interactType == "Collect" then
		return false
	end
	return true
end

return InteractableUsecase
