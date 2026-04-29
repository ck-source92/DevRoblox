local NPCSpawner = {}

local NPC_TEMPLATE = game.ServerStorage.NPCTemplate

function NPCSpawner.Spawn(id, position, speed, folder)
	local model = NPC_TEMPLATE:Clone()
	model.Name = id
	model.HumanoidRootPart.CFrame = CFrame.new(position)
	model.Humanoid.WalkSpeed = speed
	model.Parent = folder or workspace.NPCs
	return model
end

function NPCSpawner.MoveToward(model, targetPosition, speed)
	if not model or not model.Parent then
		return
	end
	model.Humanoid.WalkSpeed = speed
	model.Humanoid:MoveTo(targetPosition)
end

function NPCSpawner.Destroy(model)
	if model and model.Parent then
		model:Destroy()
	end
end

return NPCSpawner
