local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Players = game:GetService("Players")

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {
		PlayerDamage = Knit.CreateSignal(),
		PlayerHeal = Knit.CreateSignal(),
	},
})

function PlayerService:KnitInit()
	self:PlayerInit()
end

function PlayerService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:PlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:PlayerRemoving(player)
	end)
end

function PlayerService:PlayerInit()
	local DIContainer = require(ReplicatedStorage.Shared.Classes.Core.DI)
	local PlayerTakeDamageUsecase =
		require(ReplicatedStorage.Shared.Classes.Core.Applications.Usecases.TakeDamageUsecase)

	self.DataStoreService = DIContainer:Resolve("IDataStoreService")
	self.PlayerRepository = DIContainer:Resolve("IPlayerRepository", self.DataStoreService)
	self.TakeDamageUsecase = PlayerTakeDamageUsecase.new(self.PlayerRepository, {
		Publish = function(evnt, data)
			self.Client[evnt]:Fire()
		end,
	})

	-- Internal event system
	self.PlayerJoined = Signal.new()
	self.PlayerLeft = Signal.new()
end

function PlayerService:PlayerAdded(player)
	local PlayerEntity = require(ReplicatedStorage.Shared.Classes.Core.Domain.Entities.PlayerEntity)
	local playerEntity = PlayerEntity.new(player.UserId, player.Name)

	if not self.PlayerRepository:Exists(player.UserId) then
		self.PlayerRepository:Save(playerEntity)
	end

	self.PlayerJoined:Fire(player, playerEntity)
end

function PlayerService:PlayerRemoving(player)
	self.PlayerLeft:Fire(player)
end

function PlayerService.Client:TakeDamage(player: Player, damage: number)
	local success, message, data = self.Server.TakeDamageUsecase:Execute(player.UserId, damage)

	if success then
		return {
			Success = true,
			RemainingHealth = data.RemainingHealth,
			IsDefeated = data.IsDefeated,
		}
	else
		return {
			Success = false,
			Message = message,
		}
	end
end

return PlayerService
