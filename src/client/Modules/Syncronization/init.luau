local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function()
	Knit.OnStart():andThen(function()
		print("syncronization start")
		for _, module in script:GetChildren() do
			local syncronizationModule = require(module)
			syncronizationModule:Init()
		end
	end)

	print("syncronization end")
end
