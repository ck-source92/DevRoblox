-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- Directions
local Applications = StarterPlayer.StarterPlayerScripts.Client.Roact.Applications
local Contexts = StarterPlayer.StarterPlayerScripts.Client.Roact.Contexts
local AllowedApplicationsContext = require(Contexts.AllowedApplicationsContext)
local RoactHooks = require(ReplicatedStorage.Packages.Hooks)
-- local Contexts = StarterPlayer.StarterPlayerScripts.Client.Roact.Contexts
local ContextStack = require(Contexts.ContextStack)

-- Modules
local Roact = require(ReplicatedStorage.Packages.Roact)
local HUD = require(Applications.HUD.Application)

--local GlobalHoveredFrame = require(Applications.GlobalHoveredFrame.Application)

local function Root(props, hooks)
	return Roact.createElement(ContextStack, {
		providers = {
			AllowedApplicationsContext.Provider,
		},
	}, Roact.createFragment(props[Roact.Children]))
end
Root = RoactHooks.new(Roact)(Root)

local Frames = {
	Hud = Roact.createElement(require(Applications.HUD.Application)),
	Point = Roact.createElement(require(Applications.Points.Applications)),
}

-- Component
local function StoryFrame()
	return Roact.createElement(Root, {}, Frames)
end

-- Component
local function GameFrame()
	return Roact.createElement(Root, {}, {
		GameScreenGui = Roact.createElement("ScreenGui", {
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Global,
			ResetOnSpawn = false,
		}, {
			HUD = Roact.createElement(HUD),
		}),
	})
end

return {
	Story = StoryFrame,
	Game = GameFrame,
}
