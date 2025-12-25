local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- Load all services:
-- for _, v in script.Parent.Services:GetDescendants() do
-- 	if v:IsA("ModuleScript") then
-- 		require(v)
-- 	end
-- end

Knit.AddServicesDeep(script:WaitForChild("Services"))
Knit.AddServicesDeep(script:WaitForChild("Features"))
-- Knit.AddServices(script.Parent.Services)

Knit.Start()
	:andThen(function()
		print("Server Started")
	end)
	:catch(warn)
