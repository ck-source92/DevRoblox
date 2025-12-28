local Knit = require(game.ReplicatedStorage.Packages.Knit)

local KillZoneService = Knit.CreateService({ Name = "KillZoneService" })

local Players = game:GetService("Players")

function KillZoneService:KillPlayer(player)
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.Health = 0
	end
end

function KillZoneService:KnitStart()
	local killZonePart = workspace:WaitForChild("KillzonePart")
	killZonePart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			self:KillPlayer(player)
		end
	end)
end

return KillZoneService
