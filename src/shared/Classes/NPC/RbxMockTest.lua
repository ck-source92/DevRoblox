local Workspace = game:GetService("Workspace")

local RbxMockTest = {}
RbxMockTest.__index = RbxMockTest

local function GetSpawners()
	local folder = workspace:FindFirstChild("Test(ProgrammerOnly)")
	return folder:GetChildren()
end

function RbxMockTest.new(npcService)
	local self = setmetatable({}, RbxMockTest)
	self.npcService = npcService
	return self
end

-- Clone NPC
function RbxMockTest:TestSpawn(position: Vector3)
	print("[NPCService] Running test spawn...")
	if not position then
		error("[NPCService] No position provided")
		return
	end

	local spawners = GetSpawners()
	if not spawners or #spawners == 0 then
		error("[NPCService] No spawner parts found in Test(ProgrammerOnly)")
		return
	end

	local shuffledSpawners = {}
	for i, spawner in ipairs(spawners) do
		shuffledSpawners[i] = spawner
	end

	for i = #shuffledSpawners, 2, -1 do
		local j = math.random(i)
		shuffledSpawners[i], shuffledSpawners[j] = shuffledSpawners[j], shuffledSpawners[i]
	end

	for i = 1, 5 do
		local spawnerIndex = ((i - 1) % #shuffledSpawners) + 1
		local spawnerPart = shuffledSpawners[spawnerIndex]

		if not spawnerPart or not spawnerPart:IsA("BasePart") then
			warn("[NPCService] Invalid spawner at index", spawnerIndex)
			continue
		end

		local npcId = self.npcService:SpawnNPC(spawnerPart.Position)
		if npcId then
			print("[NPCService] Starting wandering for NPC ID:", npcId, "at spawner", spawnerIndex)
			self.npcService:StartNPCWandering(npcId)
		end

		task.wait(0.5)
	end

	print("[NPCService] Test spawn complete. Total NPCs:", self.npcService:GetNPCCount())
end

-- Create mock interactable objects for testing
function RbxMockTest:CreateMockInteractables(centerPosition: Vector3)
	local testFolder = Workspace:FindFirstChild("TestInteractables")
	if not testFolder then
		testFolder = Instance.new("Folder")
		testFolder.Name = "TestInteractables"
		testFolder.Parent = Workspace
	end

	-- Clear existing test objects
	testFolder:ClearAllChildren()

	-- Define the 5 interaction types
	local interactTypes = {
		"Destroy",
		"Repair",
		"Hacking",
		"Collect",
		"Scan",
	}

	-- Create 5 test objects in a circle around the center position
	for i, interactType in ipairs(interactTypes) do
		local angle = (i / 5) * math.pi * 2
		local radius = 15 -- 15 studs from center
		local offsetX = math.cos(angle) * radius
		local offsetZ = math.sin(angle) * radius

		-- Create the part
		local part = Instance.new("Part")
		part.Name = "TestObject_" .. interactType
		part.Size = Vector3.new(2, 100, 2)
		part.Position = Vector3.new(centerPosition.X + offsetX, centerPosition.Y, centerPosition.Z + offsetZ)
		part.Anchored = true
		part.CanCollide = true

		-- Color based on type for easy identification
		if interactType == "Destroy" then
			part.BrickColor = BrickColor.Red()
		elseif interactType == "Repair" then
			part.BrickColor = BrickColor.Green()
		elseif interactType == "Hacking" then
			part.BrickColor = BrickColor.Blue()
		elseif interactType == "Collect" then
			part.BrickColor = BrickColor.Yellow()
		elseif interactType == "Scan" then
			part.BrickColor = BrickColor.new("Cyan")
		end

		-- Create model wrapper
		local model = Instance.new("Model")
		model.Name = interactType .. "_Object"
		part.Parent = model
		model.PrimaryPart = part

		-- Set attributes on MODEL (InteractableEntity reads from model)
		model:SetAttribute("InteractType", interactType)
		model:SetAttribute("Map", "Test")

		model.Parent = testFolder

		print("[RbxMockTest] Created mock interactable:", interactType, "at", part.Position)
	end

	print("[RbxMockTest] Created 5 test interactables in Workspace/TestInteractables")
end

return RbxMockTest
