-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Roact = require(ReplicatedStorage.Packages.Roact)

-- local e = Roact.createElement

-- local PointsCard = Roact.Component:extend("PointsCard")

-- function PointsCard:render()
-- 	local props = self.props
-- 	local points = props.points or 0

-- 	return e("Frame", {
-- 		Size = UDim2.fromOffset(250, 120),
-- 		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
-- 		BorderSizePixel = 0,
-- 	}, {
-- 		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 12) }),

-- 		Label = e("TextLabel", {
-- 			Size = UDim2.fromScale(1, 0.5),
-- 			BackgroundTransparency = 1,
-- 			Text = "Your Points:",
-- 			TextColor3 = Color3.fromRGB(255, 255, 255),
-- 			TextSize = 20,
-- 			Font = Enum.Font.GothamMedium,
-- 		}),

-- 		Value = e("TextLabel", {
-- 			Position = UDim2.fromScale(0, 0.4),
-- 			Size = UDim2.fromScale(1, 0.5),
-- 			BackgroundTransparency = 1,
-- 			Text = tostring(points),
-- 			TextColor3 = Color3.fromRGB(180, 255, 180),
-- 			TextSize = 32,
-- 			Font = Enum.Font.GothamBold,
-- 		}),
-- 	})
-- end

-- return PointsCard
