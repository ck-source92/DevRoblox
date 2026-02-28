-- Packages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RunService = game:GetService("RunService")

local ObbyData = require(ReplicatedStorage.Shared.Classes.Obby.Domain.ObbyData)

-- Initialize dependencies
local ObbyRepository = require(ReplicatedStorage.Shared.Classes.Obby.Repositories.ObbyRepository)
local RbxObbyService = require(ReplicatedStorage.Shared.Classes.Obby.RbxObbyService)
local ObbyUseCase = require(ReplicatedStorage.Shared.Classes.Obby.Application.ObbyUseCase)
local ToggleObbyUseCase = require(ReplicatedStorage.Shared.Classes.Obby.Application.ToggleObbyUseCase)

local ObbyService = Knit.CreateService({
	Name = "ObbyService",
	Client = {},
})

function ObbyService:Init()
	self.ObbyRepository = ObbyRepository.new()
	self.RbxObbyService = RbxObbyService.new()
	self.ObbyUseCase = ObbyUseCase.new(self.ObbyRepository, self.RbxObbyService)
	self.ToggleUseCase = ToggleObbyUseCase.new(self.ObbyRepository)
end

function ObbyService:Update()
	task.spawn(function()
		local success, message = self.ObbyUseCase:Execute()
		if success then
			self:Start()
		else
			warn("[ObbyService] Failed to initialize obstacles: " .. message)
		end
	end)
end

function ObbyService:Start()
	RunService.Heartbeat:Connect(function(deltaTime)
		self:UpdateObstacles(deltaTime)
	end)
end

function ObbyService:UpdateObstacles(deltaTime: number)
	local obstacles = self.ObbyRepository:GetAll()

	for _, inst in ipairs(obstacles) do
		local shouldToggle = inst:Update(deltaTime)

		if shouldToggle then
			local success, _, obstacleObj = self.ToggleUseCase:Execute(inst.Id)

			if success then
				if obstacleObj.State == ObbyData.ObbyState.VISIBLE then
					obstacleObj:SetRandomTimers()
					self.ObbyRepository:Save(obstacleObj)
				end
			end
		end
	end
end

function ObbyService:KnitInit()
	self:Init()
end

function ObbyService:KnitStart()
	self:Update()
end

return ObbyService
