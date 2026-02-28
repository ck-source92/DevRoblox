--!strict
-- Features/Weapons/WeaponService.luau
-- Managed weapon lifecycle and combat logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WeaponDomain = require(ReplicatedStorage.Shared.Features.Weapons.Domain.Weapon)

local WEAPONS_FOLDER = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons")
local DEFAULT_SWORD_NAME = "ClassicSword"

local ANIMATIONS = {
	R15Slash = 522635514,
	R15Lunge = 522638767,
}

local WeaponService = Knit.CreateService({
	Name = "WeaponService",
	Client = {},
	_playerWeapons = {}, -- [Player] = WeaponDomain
	_boundTools = {},
})

function WeaponService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)
end

function WeaponService:_initPlayer(player: Player)
	self._playerWeapons[player] = WeaponDomain.new()

	player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(player, character)
	end)
end

function WeaponService:_onCharacterAdded(player: Player, character: Model)
	local weapon = self._playerWeapons[player]
	if not weapon then
		return
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == DEFAULT_SWORD_NAME then
			weapon.State.IsEquipped = true
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == DEFAULT_SWORD_NAME then
			weapon.State.IsEquipped = false
		end
	end)
end

-- Implementation of Sword logic (simplified version of original for the refactor demo)
function WeaponService:ToggleSword(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local sword = character:FindFirstChild(DEFAULT_SWORD_NAME) or player.Backpack:FindFirstChild(DEFAULT_SWORD_NAME)

	if sword then
		if sword.Parent == character then
			sword.Parent = player.Backpack
		else
			sword.Parent = character
		end
	else
		-- Give sword if missing
		local template = WEAPONS_FOLDER:FindFirstChild(DEFAULT_SWORD_NAME)
		if template then
			local clone = template:Clone()
			clone.Parent = character -- Force equip
		end
	end
end

function WeaponService.Client:ToggleSword(player: Player)
	self.Server:ToggleSword(player)
end

return WeaponService
