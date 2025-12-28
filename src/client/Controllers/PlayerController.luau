local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerController = Knit.CreateController({
	Name = "PlayerController",
	Client = {},
})

function PlayerController:KnitInit()
	self.PushObjectServices = Knit.GetService("PushObjectServices")
	self.PlayerService = Knit.GetService("PlayerService")

	self.PlayerService.PlayerDamage:Connect(function(data)
		self:OnPlayerDamage(data)
	end)

	self.PlayerService.PlayerHeal:Connect(function(data)
		self:OnPlayerHealed(data)
	end)
end

function PlayerController:KnitStart()
	self:UserInput()
end

function PlayerController:UserInput()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			print("[BoxController] E pressed, requesting stop pushing box")
			self.PushObjectServices:RequestStopPushing()
		end
	end)
end

function PlayerController:OnPlayerDamage(data)
	print("[PlayerController] On Player Damage : ", data)
	--[[ TODO: Update UI && Play effects
	local PlayerUI = require(script.Parent.Parent.UI.PlayerUI)
	PlayerUI:UpdateHealthBar(data.RemainingHealth)

	-- Play effects
	if data.IsDefeated then
		self:OnPlayerDefeated()
	end
	]]
end

function PlayerController:OnPlayerHealed(data)
	print("[PlayerController] On Player Healed : ", data)
	--[[ TODO: Update UI && Play effects
	local PlayerUI = require(script.Parent.Parent.UI.PlayerUI)
	PlayerUI:UpdateHealthBar(data.RemainingHealth)

	-- Play effects
	if data.IsDefeated then
		self:OnPlayerDefeated()
	end
	]]
end

function PlayerController:TakeDamage(damage: number)
	local result = self.PlayerService:TakeDamage(damage)
	if not result.Success then
		warn("Failed to take damage:", result.Message)
	end
end

return PlayerController
