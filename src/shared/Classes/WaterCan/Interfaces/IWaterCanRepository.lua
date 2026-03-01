--[[
    IWaterCanRepository  (WaterCan/Interfaces)
    ─────────────────────────────────────────
    Contract that any watering can repository must fulfill.

    The Application layer depends on this interface, not on a concrete
    implementation. Swap in a DataStore-backed repository later by creating
    a new class that satisfies these methods — nothing else changes.

    ── Method contracts ──────────────────────────────────────────────────────────
    GetCan(player, canId)           → WaterCanEntity?
    SaveCan(player, can)            → void
    DeleteCan(player, canId)        → void
    GetInventory(player)            → { [canId]: WaterCanEntity }
    InitPlayer(player)              → void   (call on PlayerAdded)
    RemovePlayer(player)            → void   (call on PlayerRemoving)
    HasPlayer(player)               → boolean
--]]

local IWaterCanRepository = {}

--- Validates that a table satisfies the repository contract.
--- Call this in tests or when registering a custom repo implementation.
function IWaterCanRepository.Validate(repo: table, label: string?)
    local lbl = label or "IWaterCanRepository"
    local required = { "GetCan", "SaveCan", "DeleteCan", "GetInventory", "InitPlayer", "RemovePlayer", "HasPlayer" }
    for _, method in ipairs(required) do
        assert(type(repo[method]) == "function",
            string.format("%s: missing method '%s'", lbl, method))
    end
end

return IWaterCanRepository
