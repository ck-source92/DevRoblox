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

function ObstacleService:Init()
	local obsFolder = workspace:WaitForChild("Obstacle")
	if not obsFolder then
		return
	end

	for _, inst in ipairs(obsFolder:GetChildren()) do
		if inst:IsA("BasePart") then
			local Id = "Obstacle_" .. tostring(#self.Obstacles + 1)
			local entity = ObstacleEntity.new(Id, inst)
			entity:SetRandomTimers()
			table.insert(self.Obstacles, entity)
		end
	end
end

function ObstacleService:StartGame()
	RunService.Heartbeat:Connect(function(deltaTime)
		self:Update(deltaTime)
	end)
end

function ObstacleService:Update(deltaTime: number)
	for _, obj in ipairs(self.Obstacles) do
		obj:Update(deltaTime)
		if obj.CurrentTimer == 0 then
			obj:SetRandomTimers()
		end
	end
end

return ObstacleService
