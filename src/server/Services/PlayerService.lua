local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {},
})

function PlayerService:KnitInit()
	self:PlayerInit()
end

function PlayerService:KnitStart() end

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
end

return PlayerService
