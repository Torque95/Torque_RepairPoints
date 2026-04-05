-- ==========================================
--  Custom Repair System — Client
-- ==========================================

local repairPoints = {
    { coords = vector3(345.61,  -1109.11, 29.41),  label = "Mission Row" },
    { coords = vector3(1146.33, -770.7,   57.56),  label = "Mirror Park" },
    { coords = vector3(-1314.38,-1256.4,  4.57),   label = "Baycity" },
    { coords = vector3(-1404.53,-456.6,   34.48),  label = "DPG" },
    { coords = vector3(-565.77, -981.48,  22.18),  label = "Little Seoul" },
    { coords = vector3(1981.49,  3778.4,  32.18),  label = "Sandy" },
    { coords = vector3(216.3,    2609.34, 46.45),  label = "Harmony" },
    { coords = vector3(-77.0,    6430.3,  31.44),  label = "Paleto" },
    { coords = vector3(-73.06,  -1340.55, 28.26),  label = "Innocence Blvd" },
    { coords = vector3(533.07,  -179.2,   53.39),  label = "Elgin Ave" },
}

local REPAIR_COST     = 1000
local REPAIR_DURATION = 8000
local DRAW_DISTANCE   = 30.0
local INTERACT_RANGE  = 9.0
local MARKER_HEIGHT   = 0.2

local isRepairing     = false
local uiVisible       = false
local drillingThread  = nil

-- ============================================================
--  Helpers
-- ============================================================

local function showUI()
    if uiVisible then return end
    uiVisible = true
    lib.showTextUI(('[E] Repair Vehicle — $%s'):format(REPAIR_COST), {
        position = 'middle',
        icon     = 'wrench',
        style    = {
            borderRadius    = 4,
            backgroundColor = '#1a1a1a',
            color           = '#f0f0f0',
        },
    })
end

local function hideUI()
    if not uiVisible then return end
    uiVisible = false
    lib.hideTextUI()
end

local function vehicleNeedsRepair(vehicle)
    return GetVehicleEngineHealth(vehicle) < 950.0
        or GetVehicleBodyHealth(vehicle)   < 950.0
end

local function openHood(vehicle)
    SetVehicleDoorOpen(vehicle, 4, false, false)
end

local function closeHood(vehicle)
    SetVehicleDoorShut(vehicle, 4, false)
end

local function startDrillingLoop()
    if drillingThread then return end
    drillingThread = CreateThread(function()
        while isRepairing do
            Wait(500)
        end
        drillingThread = nil
    end)
end

-- ============================================================
--  Confirm dialog
-- ============================================================

local function confirmRepair(vehicle)
    if not vehicleNeedsRepair(vehicle) then
        lib.notify({
            title       = 'No Repairs Needed',
            description = 'Your vehicle is already in good shape.',
            type        = 'info',
        })
        return
    end

    lib.callback('customRepair:getBalances', false, function(balances)
        if not balances then return end

        local cash       = balances.cash
        local bank       = balances.bank
        local affordable = cash >= REPAIR_COST or bank >= REPAIR_COST

        local paySource
        if cash >= REPAIR_COST then
            paySource = ('cash ($%s available)'):format(cash)
        elseif bank >= REPAIR_COST then
            paySource = ('bank ($%s available)'):format(bank)
        end

        local content
        if affordable then
            content = ('**Cost:** $%s\n**Charged to:** %s\n\nProceed with repair?'):format(REPAIR_COST, paySource)
        else
            content = ('**Cost:** $%s\n\n❌ Insufficient funds\nCash: $%s  |  Bank: $%s'):format(REPAIR_COST, cash, bank)
        end

        local confirmed = lib.alertDialog({
            header   = '🔧 Vehicle Repair',
            content  = content,
            centered = true,
            cancel   = affordable,
        })

        if confirmed == 'confirm' then
            TriggerServerEvent('customRepair:tryRepair')
        end
    end)
end

-- ============================================================
--  UI safety watcher
-- ============================================================

CreateThread(function()
    while true do
        Wait(500)
        if uiVisible then
            local ped = PlayerPedId()
            if IsEntityDead(ped) or not IsPedInAnyVehicle(ped, false) or isRepairing then
                hideUI()
            end
        end
    end
end)

-- ============================================================
--  Main proximity loop
-- ============================================================

CreateThread(function()
    while true do
        local sleep     = 1500
        local ped       = PlayerPedId()
        local coords    = GetEntityCoords(ped)
        local inVehicle = IsPedInAnyVehicle(ped, false)
        local nearAny   = false

        if inVehicle and not isRepairing then
            local vehicle = GetVehiclePedIsIn(ped, false)

            for _, point in ipairs(repairPoints) do
                local dist = #(coords - point.coords)

                if dist < DRAW_DISTANCE then
                    sleep = 0

                    DrawMarker(
                        2,
                        point.coords.x, point.coords.y, point.coords.z + MARKER_HEIGHT,
                        0, 0, 0,
                        0, 0, 0,
                        0.8, 0.8, 0.5,
                        0, 200, 80, 120,
                        false, true, 2, nil, nil, false
                    )

                    if dist < INTERACT_RANGE then
                        nearAny = true
                        showUI()

                        if IsControlJustReleased(0, 38) and not isRepairing then
                            confirmRepair(vehicle)
                        end
                    end
                end
            end
        end

        -- Always evaluated — never nested inside inVehicle
        if not nearAny then
            hideUI()
        end

        Wait(sleep)
    end
end)

-- ============================================================
--  Repair handler
-- ============================================================

RegisterNetEvent('customRepair:startRepair', function(paySource)
    if isRepairing then return end
    isRepairing = true

    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not vehicle or vehicle == 0 then
        isRepairing = false
        return
    end

    openHood(vehicle)
    startDrillingLoop()

    SendNUIMessage({
        action    = 'startRepair',
        duration  = REPAIR_DURATION,
        paySource = paySource or '',
    })

    CreateThread(function()
        local elapsed = 0
        while elapsed < REPAIR_DURATION and isRepairing do
            DisableControlAction(0, 30, true)   -- move left/right
            DisableControlAction(0, 31, true)   -- move up/down
            DisableControlAction(0, 21, true)   -- sprint
            DisableControlAction(0, 22, true)   -- jump
            DisableControlAction(0, 23, true)   -- exit vehicle (F)
            DisableControlAction(0, 69, true)   -- vehicle attack (left mouse)
            DisableControlAction(0, 70, true)   -- vehicle attack 2 (right mouse)
            DisableControlAction(0, 92, true)   -- vehicle aim
            DisableControlAction(0, 71, true)   -- accelerate
            DisableControlAction(0, 72, true)   -- brake
            DisableControlAction(0, 135, true)  -- seatbelt / ragdoll (B)
            DisableControlAction(27, 23, true)  -- exit vehicle group 27
            DisableControlAction(1, 23, true)   -- exit vehicle group 1
            elapsed = elapsed + GetFrameTime() * 1000
            Wait(0)
        end
    end)

    Wait(REPAIR_DURATION)

    closeHood(vehicle)
    isRepairing = false
    SendNUIMessage({ action = 'stopRepair' })

    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true)
    PlaySoundFrontend(-1, 'CHALICE_CORRECT_DING', 'HUD_MINI_GAME_SOUNDSET', true)
    lib.notify({
        title       = 'Repair Complete',
        description = 'Your vehicle is good to go.',
        type        = 'success',
    })
end)

-- ============================================================
--  Blips
-- ============================================================

CreateThread(function()
    for _, point in ipairs(repairPoints) do
        local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
        SetBlipSprite(blip, 446)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.55)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(('Repair — %s'):format(point.label))
        EndTextCommandSetBlipName(blip)
    end
end)
