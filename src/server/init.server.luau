local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
-- Services
for _, file in pairs(script.Services:GetChildren()) do
	require(file)
end
Knit.Start()
	:andThen(function()
		print("Server Started")
	end)
	:catch(warn)
