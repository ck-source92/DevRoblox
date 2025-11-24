local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoactHooks = require(ReplicatedStorage.Packages.Hooks)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Roduxhooks = require(ReplicatedStorage.Packages.Roduxhooks)

local e = Roact.createElement

function PointsApp(_, hooks)

	return e("ScreenGui", { ResetOnSpawn = false }, {
		Main = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.05, 0.5),
			Size = UDim2.fromOffset(300, 150),
			BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		}, {
			Label = e("TextLabel", {
				Text = "Point",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 24,
				Font = Enum.Font.GothamBold,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.6),
			}),
			Button = e("TextButton", {
				Text = "+5 Points",
				Position = UDim2.fromScale(0.1, 0.6),
				Size = UDim2.fromScale(0.8, 0.3),
			}),
		}),
	})
end

PointsApp = RoactHooks.new(Roact)(PointsApp)
return PointsApp
