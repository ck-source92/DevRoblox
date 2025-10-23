local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

-- Knit.AddControllers(script.Parent:WaitForChild("Controllers"))
for _, file in pairs(script.Controllers:GetChildren()) do
	require(file)
end

local PointsApp = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Applications.Points.Applications)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

Knit.Start()
	:andThen(function()
		print("Knit Client Started")
	end)
	:catch(warn)

local Root = require(script.Roact.Applications.Root.Application)
local Sync = require(StarterPlayer.StarterPlayerScripts.Client.Modules.Syncronization)
Sync()

Roact.mount(
	Roact.createElement(RoactRodux.StoreProvider, { store = Store }, {
		App = Roact.createElement(PointsApp),
		-- GameScreenGui = Roact.createElement(Root.Game),
	}),
	Players.LocalPlayer.PlayerGui,
	"UI"
)
