-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Roact = require(ReplicatedStorage.Packages.Roact)

-- Code
local function ContextStack(props)
	local mostRecent =
		Roact.createElement(props.providers[#props.providers], {}, Roact.createFragment(props[Roact.Children]))
	for providerIndex = #props.providers - 1, 1, -1 do
		mostRecent = Roact.createElement(props.providers[providerIndex], {}, mostRecent)
	end
	return mostRecent
end

return ContextStack
