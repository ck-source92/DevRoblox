--[[
    UpgradeMachineUseCase  (Machine/Application)
    ─────────────────────────────────────────────
    Validates and applies the next upgrade tier to a machine.

    Currency deduction is stubbed — inject CurrencyService when ready.

    Result: { success: boolean, message: string, newUpgradeLevel: number? }
--]]

local MachineResolver = require(script.Parent.MachineResolver)

local UpgradeMachineUsecase = {}
UpgradeMachineUsecase.__index = UpgradeMachineUsecase

---@param machineRepo   IMachineRepository
---@param currencyService  table?  optional, provide when currency is implemented
function UpgradeMachineUsecase.new(machineRepo: table, currencyService: table?)
	return setmetatable({
		_machines = machineRepo,
		_currency = currencyService,
	}, UpgradeMachineUsecase)
end

function UpgradeMachineUsecase:Execute(player: any, machineId: string): table
	local machine = self._machines:GetMachine(machineId)
	if not machine then
		return { success = false, message = "Machine not found." }
	end

	local profile = MachineResolver:Resolve(machine.machineType, machine.upgradeLevel)
	local nextLevel = machine.upgradeLevel + 1

	if nextLevel > profile.maxUpgrade then
		return { success = false, message = "Machine is already at max upgrade." }
	end

	local cost = MachineResolver:GetNextUpgradeCost(machine.machineType, machine.upgradeLevel)

	-- ── Currency check (uncomment when CurrencyService is ready) ─────────────
	-- if self._currency then
	--     if not self._currency:CanAfford(player, cost) then
	--         return { success = false, message = "Need " .. cost .. " coins." }
	--     end
	--     self._currency:Deduct(player, cost)
	-- end
	-- ─────────────────────────────────────────────────────────────────────────

	machine:Upgrade()

	return {
		success = true,
		message = "Upgraded to Tier " .. nextLevel .. ".",
		newUpgradeLevel = nextLevel,
		cost = cost,
	}
end

return UpgradeMachineUsecase
