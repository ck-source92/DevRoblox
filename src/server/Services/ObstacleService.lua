local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ObstacleState = require(ReplicatedStorage.Shared.Classes.Obstacles.Domain.ObstacleState)
local ObstacleEntity = require(ReplicatedStorage.Shared.Classes.Obstacles.Domain.ObstacleEntity)

local ObstacleService = Knit.CreateService({
	Name = "ObstacleService",
	Client = {},

	Obstacles = {},
	_entity = {},
})

function ObstacleService:KnitStart()
	self:Init()
	self:StartGame()
end
--[[
	function ObstacleService:Init()
		local obsFolder = workspace:WaitForChild("Obstacle")
		if not obsFolder then
			return
		end
		
		for _, inst in ipairs(obsFolder:GetChildren()) do
			if inst:IsA("BasePart") then
				local obs = {
					Part = inst,
					Inactive = math.random(2, 4),
					Active = math.random(3, 4),
					State = "Visible",
					Timer = 0,
					Transparency = inst.Transparency,
				}
				table.insert(self.Obstacles, obs)
			end
		end
	end
	]]

function ObstacleService:Init()
	local obsFolder = workspace:WaitForChild("Obstacle")
	if not obsFolder then
		return
	end

	for _, inst in ipairs(obsFolder:GetChildren()) do
		if inst:IsA("BasePart") then
			local Id = "Obstacle_" .. tostring(#self.Obstacles + 1)
			local entity = ObstacleEntity.new(Id, inst)
			entity.Obstacle:SetRandomTimers()
			table.insert(self.Obstacles, entity)
		end
	end
end

function ObstacleService:StartGame()
	RunService.Heartbeat:Connect(function(deltaTime)
		-- self:Update(deltaTime)
		ObstacleEntity:Update(deltaTime)
	end)
end

function ObstacleService:Update(deltaTime: number)
	for _, obj in ipairs(self.Obstacles) do
		print("[debug] obj :", obj)
		-- obj:Update(deltaTime)

		-- obj.Timer = obj.Timer + deltaTime
		-- if obj.State == "Visible" then
		-- 	if obj.Timer >= obj.Active then -- Active = visible duration
		-- 		self:Inactive(obj)
		-- 		obj.Timer = 0
		-- 	end
		-- elseif obj.State == "Invisible" then -- Fixed comment
		-- 	if obj.Timer >= obj.Inactive then
		-- 		self:Active(obj)
		-- 		obj.Timer = 0
		-- 		-- Reset with new random times
		-- 		obj.Active = math.random(3, 4)
		-- 		obj.Inactive = math.random(2, 4)
		-- 	end
		-- end
	end
end

function ObstacleService:Active(obstacle: table)
	if not obstacle then
		return
	end

	obstacle.State = "Visible"
	obstacle.Part.Transparency = obstacle.Transparency

	obstacle.Part.Color = Color3.fromRGB(255, 50, 50)
end

function ObstacleService:Inactive(obstacle: table)
	if not obstacle then
		return
	end

	obstacle.State = "Invisible"
	obstacle.Part.Transparency = 1

	obstacle.Part.Color = Color3.fromRGB(50, 50, 255)
end

return ObstacleService
