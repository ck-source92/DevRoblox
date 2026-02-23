local Workspace = game:GetService("Workspace")
local InteractableEntity = require(script.Parent.Parent.Domain.InteractableEntity)

local InteractableRepository = {}
InteractableRepository.__index = InteractableRepository

function InteractableRepository.new()
	local self = setmetatable({}, InteractableRepository)

	self.interactables = {} :: { [string]: { Model? } }

	return self
end

-- Discover all interactable objects on a specific map
function InteractableRepository:DiscoverInteractables(mapName: string): { any }
	local interactables = {}

	local maps = Workspace:FindFirstChild("Maps")
	if not maps then
		warn("[InteractableRepository] No Maps folder found in workspace")
		return interactables
	end

	local map = maps:FindFirstChild(mapName)
	if not map then
		warn("[InteractableRepository] Map not found:", mapName)
		return interactables
	end

	local npcArea = map:FindFirstChild("NPCArea")
	if not npcArea then
		return interactables
	end

	local interactableFolder = npcArea:FindFirstChild("Interactable")
	if not interactableFolder then
		return interactables
	end

	for _, model in ipairs(interactableFolder:GetChildren()) do
		if model:IsA("Model") then
			local entity = InteractableEntity.new(model)
			table.insert(interactables, entity)
		end
	end
	self.interactables[mapName] = interactables
	print("[InteractableRepository] Discovered", #interactables, "interactables on", mapName)

	return interactables
end

-- Get all interactables for a map (uses cache if available)
function InteractableRepository:GetInteractables(mapName: string): { any }
	if not self.interactables[mapName] then
		return self:DiscoverInteractables(mapName)
	end

	return self.interactables[mapName]
end

-- Get a random available interactable
function InteractableRepository:GetRandomInteractable(mapName: string): any?
	local interactables = self:GetInteractables(mapName)

	local available = {}
	for _, interactable in ipairs(interactables) do
		if interactable:IsAvailable() then
			table.insert(available, interactable)
		end
	end
	if #available == 0 then
		return nil
	end
	return available[math.random(1, #available)]
end

function InteractableRepository:SetOccupied(interactable: any, occupied: boolean)
	interactable:SetOccupied(occupied)
end

--[[ DEBUG MODE
	- Set enable @Config.lua -> NPC folder
]]
function InteractableRepository:DiscoverTestInteractables()
	local interactables = {}
	local testFolder = Workspace:FindFirstChild("TestInteractables")
	if not testFolder then
		warn("[InteractableRepository] No TestInteractables folder found in workspace")
		return interactables
	end
	for _, model in ipairs(testFolder:GetChildren()) do
		if model:IsA("Model") then
			local entity = InteractableEntity.new(model)
			table.insert(interactables, entity)
		end
	end
	-- Cache as "Test" map
	self.interactables["Test"] = interactables
	print("[InteractableRepository] Discovered", #interactables, "test interactables from Workspace/TestInteractables")
	return interactables
end

return InteractableRepository
