-- Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Modules
local Roact = require(ReplicatedStorage.Packages.Roact)
local Roduxhooks = require(ReplicatedStorage.Packages.Roduxhooks)
local Application = require(script.Parent.Application)

local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

-- Code
return function(target)
	local handle = Roact.mount(
		Roact.createElement(Roduxhooks.Provider, {
			store = Store,
		}, {
			Roact.createElement(Application.Story),
		}),
		target,
		"Root"
	)
	return function()
		Roact.unmount(handle)
	end
end
