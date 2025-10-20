local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(script.Parent:WaitForChild("Services"))

Knit.Start()
	:andThen(function()
		print("Server Started")
		local spawner = Knit.GetService("SpawnerService")
		for i = 1, 10 do
			local pos = Vector3.new(math.random(-50, 50), 2, math.random(-50, 50))
			spawner:SpawnObject("PartCoin", pos)
		end
	end)
	:catch(warn)
