--[[
    AddXPUseCase  (WaterCan/Application)
    ─────────────────────────────────────────
    Applies an XP amount to a specific watering can for a player.
    Handles level-ups and returns the result for the caller to react to
    (fire signals, update UI, etc.).

    Depends on IWaterCanRepository (injected).
    Called every tick by MachineTickUseCase.

    Result shape:
    {
        can       : WaterCanEntity   updated entity
        levelUps  : number              how many levels were gained (0 = none)
        newLevel  : number
        newXP     : number
    }
--]]

local AddXPUseCase = {}
AddXPUseCase.__index = AddXPUseCase

function AddXPUseCase.new(repo: table)
	assert(repo, "AddXPUseCase: repo is required")
	return setmetatable({ _repo = repo }, AddXPUseCase)
end

--- Applies `xpAmount` to the given can. Returns result table or nil if not found.
function AddXPUseCase:Execute(player: Player, canId: string, xpAmount: number): table?
	local can = self._repo:GetCan(player, canId)
	if not can then
		return nil
	end

	local result = can:ApplyXP(xpAmount)
	self._repo:SaveCan(player, can)

	return {
		can = can,
		levelUps = result.levelUps,
		newLevel = result.newLevel,
		newXP = result.newXP,
	}
end

return AddXPUseCase
