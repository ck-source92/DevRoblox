local RS = game:GetService("ReplicatedStorage")
local Knit = require(RS.Packages.Knit)

local GameController = Knit.CreateController({ Name = "GameController" })

local GameService = nil

function GameController:KnitInit()
	GameService = Knit.GetService("GameService")
end

function GameController:KnitStart()
	GameService.OnDodgeResult:Connect(function(success)
		if success then
			print("[GameController] Dodge successful!")
			-- UIController:ShowDodgeSuccess()
		else
			print("[GameController] Dodge failed!")
			-- UIController:ShowDodgeFail()
		end
	end)

	-- Listen game over
	GameService.OnGameOver:Connect(function()
		-- UIController:ShowGameOver()
	end)

	-- Listen game mulai
	GameService.OnGameStart:Connect(function()
		-- UIController:ShowCountdownDone()
	end)

	self:_SetupDodgeTriggers()
end

function GameController:_SetupDodgeTriggers()
	for _, obj in ipairs(workspace.DodgeObjects:GetChildren()) do
		obj.Touched:Connect(function(hit)
			local char = game.Players.LocalPlayer.Character
			if hit:IsDescendantOf(char) then
				local objSkill = obj:GetAttribute("Skill") or 50
				GameService:AttemptDodge(objSkill)
			end
		end)
	end
end

return GameController
