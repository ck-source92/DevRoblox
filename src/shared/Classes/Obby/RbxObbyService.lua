local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

local RbxObbyService = {}
RbxObbyService.__index = RbxObbyService

function RbxObbyService.new()
	local self = setmetatable({}, RbxObbyService)
	return self
end

function RbxObbyService:FindObstacles()
	local ObbyFolder = workspace:FindFirstChild("Lobby")
		and workspace.Lobby:FindFirstChild("Environment")
		and workspace.Lobby.Environment:FindFirstChild("Obby")

	local NewObbyRoot = workspace:FindFirstChild("NewLobby") and workspace.NewLobby:FindFirstChild("Obby")

	if not ObbyFolder and not NewObbyRoot then
		warn("[RbxObbyService] No obstacles found")
		return {}
	end

	local obstacles = {}

	local function AddObstacles(folder, includeFolder, forcedType)
		if not folder then
			return
		end
		if includeFolder then
			if forcedType and not folder:GetAttribute("ObbyType") then
				folder:SetAttribute("ObbyType", forcedType)
			end
			table.insert(obstacles, folder)
		else
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Model") or child:IsA("BasePart") then
					if forcedType and not child:GetAttribute("ObbyType") then
						child:SetAttribute("ObbyType", forcedType)
					end
					table.insert(obstacles, child)
				end
			end
		end
	end

	-- Legacy Obby
	if ObbyFolder then
		AddObstacles(ObbyFolder:FindFirstChild("Obstacle1"), true)
		AddObstacles(ObbyFolder:FindFirstChild("Obstacle2"), false)
		AddObstacles(ObbyFolder:FindFirstChild("Obstacle3"), true)
	end

	-- New Lobby Lasers
	if NewObbyRoot then
		for i = 1, 3 do
			local obstacleFolder = NewObbyRoot:FindFirstChild("Obstacle" .. i)
			local lasersFolder = obstacleFolder and obstacleFolder:FindFirstChild("Lasers")
			if lasersFolder then
				AddObstacles(lasersFolder:FindFirstChild("LaserVertical"), false, ObbyData.ObbyType.LASER_VERTICAL)
				AddObstacles(lasersFolder:FindFirstChild("LaserHorizontal"), false, ObbyData.ObbyType.LASER_HORIZONTAL)
			end
		end
	end

	print("[RbxObbyService] Found " .. #obstacles .. " obstacles")

	return obstacles
end

function RbxObbyService:SetPartVisibility(part: BasePart, isVisible: boolean)
	if not part then
		warn("[RbxObbyService] SetPartVisibility called with nil part")
		return
	end
	if isVisible then
		part.Transparency = 0
	else
		part.Transparency = 1
		part.CanCollide = false
	end
end

return RbxObbyService
