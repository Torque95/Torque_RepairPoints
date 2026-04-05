-- ==========================================
--  Custom Repair System — Server
-- ==========================================

local QBCore      = exports['qb-core']:GetCoreObject()
local REPAIR_COST = 1000
local cooldowns   = {}
local COOLDOWN_MS = 10000

-- ── Helpers ──────────────────────────────────────────────────────────────

local function notify(src, msg, nType)
    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'Vehicle Repair',
        description = msg,
        type        = nType,
    })
end

local function isOnCooldown(src)
    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < COOLDOWN_MS then
        return true
    end
    cooldowns[src] = now
    return false
end

-- ── Balance callback ──────────────────────────────────────────────────────

lib.callback.register('customRepair:getBalances', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end

    return {
        cash = Player.Functions.GetMoney('cash'),
        bank = Player.Functions.GetMoney('bank'),
    }
end)

-- ── Repair event ──────────────────────────────────────────────────────────

RegisterServerEvent('customRepair:tryRepair', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if isOnCooldown(src) then
        notify(src, 'Please wait before requesting another repair.', 'error')
        return
    end

    local cash = Player.Functions.GetMoney('cash')
    local bank = Player.Functions.GetMoney('bank')

    if cash >= REPAIR_COST then
        Player.Functions.RemoveMoney('cash', REPAIR_COST, 'vehicle-repair')
        TriggerClientEvent('customRepair:startRepair', src, 'cash')
        notify(src, ('$%s deducted from cash.'):format(REPAIR_COST), 'info')
    elseif bank >= REPAIR_COST then
        Player.Functions.RemoveMoney('bank', REPAIR_COST, 'vehicle-repair')
        TriggerClientEvent('customRepair:startRepair', src, 'bank')
        notify(src, ('$%s deducted from bank.'):format(REPAIR_COST), 'info')
    else
        notify(src, ('You need $%s in cash or bank.'):format(REPAIR_COST), 'error')
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)