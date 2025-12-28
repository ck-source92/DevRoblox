-- Knit Packages
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataService

local WeaponService = Knit.CreateService({
	Name = "WeaponService",
	Client = {},

	ToolEquipped = {},
	_boundTools = {},
})

local BASE_URL = "rbxassetid://"

local DAMAGE_VALUES = {
	BaseDamage = 5,
	SlashDamage = 10,
	LungeDamage = 30,
}

local ANIMATIONS = {
	R15Slash = 522635514,
	R15Lunge = 522638767,
}

--|| Client Functions ||--

---------------------------------------------------------------------
-- // Config
---------------------------------------------------------------------

local WEAPONS_FOLDER = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons")
local DEFAULT_SWORD_NAME = "ClassicSword"

---------------------------------------------------------------------
-- // Internal helpers
---------------------------------------------------------------------

local function getWeaponTemplate(weaponName: string?): Tool?
	weaponName = weaponName or DEFAULT_SWORD_NAME

	local tool = WEAPONS_FOLDER:FindFirstChild(weaponName)
	if not tool or not tool:IsA("Tool") then
		warn(("[WeaponService] Weapon %q not found or not a Tool"):format(weaponName))
		return nil
	end

	return tool
end

local function destroyAllTools(player: Player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end

	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end
end

local function isTeamMate(p1: Player?, p2: Player?)
	if not p1 or not p2 then
		return false
	end
	if p1.Neutral or p2.Neutral then
		return false
	end
	return p1.TeamColor == p2.TeamColor
end

-- Bind one sword tool instance (template or clone)
function WeaponService:_bindSword(tool: Tool)
	if self._boundTools[tool] then
		return
	end
	self._boundTools[tool] = true

	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("[WeaponService] Sword has no Handle:", tool:GetFullName())
		return
	end

	local state = {
		Tool = tool,
		Handle = handle,
		-- Damage = DAMAGE_VALUES.BaseDamage,
		ToolEquipped = false,
		LastAttack = 0,
		Player = nil :: Player?,
		Character = nil :: Model?,
		Humanoid = nil :: Humanoid?,
		Torso = nil :: BasePart?,
	}

	-- Particle spam (like your original script)
	for _, v in ipairs(handle:GetChildren()) do
		if v:IsA("ParticleEmitter") then
			v.Rate = 20
		end
	end

	local sounds = {
		Slash = handle:FindFirstChild("SwordSlash") :: Sound?,
		Lunge = handle:FindFirstChild("SwordLunge") :: Sound?,
		Unsheath = handle:FindFirstChild("Unsheath") :: Sound?,
	}

	local function checkIfAlive(): boolean
		local player = state.Player
		local character = state.Character
		local humanoid = state.Humanoid
		local torso = state.Torso

		if not player or not player.Parent then
			return false
		end
		if not character or not character.Parent then
			return false
		end
		if not humanoid or not humanoid.Parent then
			return false
		end
		if humanoid.Health <= 0 then
			return false
		end
		if not torso or not torso.Parent then
			return false
		end

		return true
	end

	local function tagHumanoid(humanoid: Humanoid, player: Player)
		local creator = Instance.new("ObjectValue")
		creator.Name = "creator"
		creator.Value = player
		creator.Parent = humanoid
		Debris:AddItem(creator, 2)
	end

	local function untagHumanoid(humanoid: Humanoid)
		for _, child in ipairs(humanoid:GetChildren()) do
			if child:IsA("ObjectValue") and child.Name == "creator" then
				child:Destroy()
			end
		end
	end

	local function blow(hit: BasePart)
		if not hit or not hit.Parent or not checkIfAlive() or not state.ToolEquipped then
			return
		end

		local character = state.Character
		if not character then
			return
		end

		-- Make sure the handle is actually welded to the arm
		local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
		if not rightArm then
			return
		end

		local rightGrip = rightArm:FindFirstChild("RightGrip")
		if not rightGrip or (rightGrip.Part0 ~= handle and rightGrip.Part1 ~= handle) then
			return
		end

		local targetChar = hit.Parent
		if targetChar == character then
			return
		end

		local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local attacker = state.Player
		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)

		if targetPlayer and (targetPlayer == attacker or isTeamMate(attacker, targetPlayer)) then
			return
		end

		if not attacker then
			return
		end

		untagHumanoid(humanoid)
		tagHumanoid(humanoid, attacker)

		-- humanoid:TakeDamage(state.Damage)
	end

	local function playR6Anim(name: string)
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = name
		anim.Parent = tool
	end

	local function ensureR15Animation(name: string, assetId: number): Animation
		local existing = tool:FindFirstChild(name)
		if existing and existing:IsA("Animation") then
			return existing
		end

		local anim = Instance.new("Animation")
		anim.Name = name
		anim.AnimationId = BASE_URL .. assetId
		anim.Parent = tool
		return anim
	end

	local function playR15Anim(name: string, assetId: number)
		local humanoid = state.Humanoid
		if not humanoid then
			return
		end

		local anim = ensureR15Animation(name, assetId)
		local track = humanoid:LoadAnimation(anim)
		track:Play(0)
	end

	local function attack()
		-- state.Damage = DAMAGE_VALUES.SlashDamage

		if sounds.Slash then
			sounds.Slash:Play()
		end

		local humanoid = state.Humanoid
		if not humanoid then
			return
		end

		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			playR6Anim("Slash")
		else
			playR15Anim("R15Slash", ANIMATIONS.R15Slash)
		end
	end

	local function lunge()
		-- state.Damage = DAMAGE_VALUES.LungeDamage

		if sounds.Lunge then
			sounds.Lunge:Play()
		end

		local humanoid = state.Humanoid
		if humanoid then
			if humanoid.RigType == Enum.HumanoidRigType.R6 then
				playR6Anim("Lunge")
			else
				playR15Anim("R15Lunge", ANIMATIONS.R15Lunge)
			end
		end

		task.wait(0.8)
		-- state.Damage = DAMAGE_VALUES.SlashDamage
	end

	local function onActivated()
		if not tool.Enabled or not state.ToolEquipped or not checkIfAlive() then
			return
		end

		tool.Enabled = false

		-- Same trick as your original: use Stepped time to detect double-click (lunge)
		local now = RunService.Stepped:Wait()

		if now - state.LastAttack < 0.2 then
			lunge()
		else
			attack()
		end

		state.LastAttack = now
		-- state.Damage = DAMAGE_VALUES.BaseDamage

		-- Make sure R15 animations exist (only needs to happen once, cheap anyway)
		ensureR15Animation("R15Slash", ANIMATIONS.R15Slash)
		ensureR15Animation("R15Lunge", ANIMATIONS.R15Lunge)

		tool.Enabled = true
	end

	local function onEquipped()
		local character = tool.Parent
		if not character or not character:IsA("Model") then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local torso = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")

		state.Player = player
		state.Character = character
		state.Humanoid = humanoid
		state.Torso = torso

		if not checkIfAlive() then
			return
		end

		state.ToolEquipped = true

		if sounds.Unsheath then
			sounds.Unsheath:Play()
		end
	end

	local function onUnequipped()
		state.ToolEquipped = false
	end

	-- Connect events on this Tool instance
	tool.Enabled = true
	tool.Activated:Connect(onActivated)
	tool.Equipped:Connect(onEquipped)
	tool.Unequipped:Connect(onUnequipped)

	handle.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") then
			blow(hit)
		end
	end)
end

function WeaponService:_setSwordEquipped(player: Player, value: boolean)
	self.ToolEquipped[player] = value
end

---------------------------------------------------------------------
-- // Public API (server-side)
---------------------------------------------------------------------

function WeaponService:IsSwordEquipped(player: Player): boolean
	return self.ToolEquipped[player] == true
end

-- Give weapon into Backpack (does NOT auto-equip)
function WeaponService:GiveWeapon(player: Player, weaponName: string?)
	local template = getWeaponTemplate(weaponName)
	if not template then
		return nil
	end

	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")

	-- destroyAllTools(player)

	local clone = template:Clone()
	clone.Parent = backpack

	return clone
end

function WeaponService:GiveSword(player: Player)
	return self:GiveWeapon(player, DEFAULT_SWORD_NAME)
end

-- Force equip sword
function WeaponService:EquipSword(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	local sword = character:FindFirstChild(DEFAULT_SWORD_NAME) or backpack:FindFirstChild(DEFAULT_SWORD_NAME)

	-- If player has no sword at all, give one then try again
	if not sword then
		local ok
		self:GiveSword(player)
		if not ok then
			return
		end
		sword = backpack:FindFirstChild(DEFAULT_SWORD_NAME)
		if not sword then
			return
		end
	end

	humanoid:EquipTool(sword)
end

-- Unequip any tools (including sword)
function WeaponService:UnequipSword(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid:UnequipTools()
	self:_setSwordEquipped(player, false)
end

-- Toggle sword: if equipped → unequip, otherwise equip
function WeaponService:ToggleSword(player: Player)
	if self:IsSwordEquipped(player) then
		self:UnequipSword(player)
	else
		self:EquipSword(player)
	end
end

---------------------------------------------------------------------
-- // Client ↔ Server API (Knit)
---------------------------------------------------------------------

function WeaponService.Client:RequestSword(player)
	return self.Server:GiveSword(player)
end

function WeaponService.Client:ToggleSword(player)
	self.Server:ToggleSword(player)
end

function WeaponService.Client:IsSwordEquipped(player)
	return self.Server:IsSwordEquipped(player)
end

---------------------------------------------------------------------
-- // Knit lifecycle
---------------------------------------------------------------------

function WeaponService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self.ToolEquipped[player] = false

		player.CharacterAdded:Connect(function(character)
			-- Reset on respawn
			self.ToolEquipped[player] = false

			local function onChildAdded(child: Instance)
				if child:IsA("Tool") and child.Name == DEFAULT_SWORD_NAME then
					self:_setSwordEquipped(player, true)
				end
			end

			local function onChildRemoved(child: Instance)
				if child:IsA("Tool") and child.Name == DEFAULT_SWORD_NAME then
					self:_setSwordEquipped(player, false)
				end
			end

			character.ChildAdded:Connect(onChildAdded)
			character.ChildRemoved:Connect(onChildRemoved)

			-- Initial check (in case sword is already in character)
			for _, child in ipairs(character:GetChildren()) do
				onChildAdded(child)
			end
		end)
	end)
end

return WeaponService
