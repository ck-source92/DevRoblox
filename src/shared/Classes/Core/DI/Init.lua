local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DIConstruct = require(ReplicatedStorage.Shared.Classes.Core.DI.DIConstruct)

local Container = DIConstruct.new()

-- Singleton True
Container:Register(
	"IDataStoreService",
	require(ReplicatedStorage.Shared.Classes.Core.Services.RbxDataStoreService),
	true
)

-- Singleton False
Container:Register(
	"IPlayerRepository",
	require(ReplicatedStorage.Shared.Classes.Core.Infrastructures.Repositories.PlayerRepository),
	false
)

return Container
