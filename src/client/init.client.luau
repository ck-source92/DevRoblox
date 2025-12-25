local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

-- Knit.AddControllers(script.Parent.Controllers)
Knit.AddControllersDeep(script:WaitForChild("Controllers"))
Knit.AddControllersDeep(script:WaitForChild("Features"))

Knit.Start()
	:andThen(function()
		print("[Client] Knit Client Started")

		local Root = require(script.Roact.Applications.Root.Application)
		local Sync = require(StarterPlayer.StarterPlayerScripts.Client.Modules.Syncronization)
		Sync()

		Roact.mount(
			Roact.createElement(RoactRodux.StoreProvider, { store = Store }, {
				GameScreenGui = Roact.createElement(Root.Game),
			}),
			Players.LocalPlayer.PlayerGui,
			"UI"
		)
		print("[Client] Knit Client Ended")
	end)
	:catch(warn)
