local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

return function()
	Knit.OnStart():andThen(function()
		print("[Syncronization] start")
		for _, module in script:GetChildren() do
			local syncronizationModule = require(module)
			syncronizationModule:Init()
		end
	end)

	print("[Syncronization] end")
end
