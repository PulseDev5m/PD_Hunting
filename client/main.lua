local playerInventory = {}
local nearSellSpot    = false
local currentSellSpot = nil


local allAnimals = {}

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for model, _ in pairs(Config.AnimalValues) do
        allAnimals[#allAnimals + 1] = model
    end

    TriggerServerEvent('hunt:server:requestData')
    SetupBlips()
    StartSpawning()
end)

function SetupBlips()
    if not Config.Settings.EnableBlips then return end

    for _, spot in ipairs(Config.SellSpots) do
        local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(blip, spot.blipSprite)
        SetBlipColour(blip, spot.blipColor)
        SetBlipScale(blip, spot.blipScale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(spot.label)
        EndTextCommandSetBlipName(blip)
    end

    for _, area in ipairs(Config.HuntingAreas) do
        local blip = AddBlipForCoord(area.coords.x, area.coords.y, area.coords.z)
        SetBlipSprite(blip, 68)
        SetBlipColour(blip, 2)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(area.label)
        EndTextCommandSetBlipName(blip)
    end
end

local areaAnimals = {}

function IsOnRoad(x, y, z)
    local nodePos = GetClosestRoad(x, y, z, 1.0, 1, false)
    if nodePos then
        local dist = #(vector3(x, y, z) - nodePos)
        if dist < 15.0 then return true end
    end
    return false
end

function GetCoordInArea(area)
    local attempts = 0
    while attempts < 40 do
        attempts = attempts + 1
        local angle  = math.random() * 2 * math.pi
        local radius = math.random(10, math.floor(area.radius))
        local x      = area.coords.x + radius * math.cos(angle)
        local y      = area.coords.y + radius * math.sin(angle)

        local found, z = GetGroundZFor_3dCoord(x, y, area.coords.z + 200.0, false)
        if not found then
            found, z = GetGroundZFor_3dCoord(x, y, 100.0, false)
        end

        if found and z > 20.0 and not IsOnRoad(x, y, z) then
            return x, y, z
        end
    end
    return nil
end

function SpawnAnimalInArea(areaIndex, area)
    local x, y, z = GetCoordInArea(area)
    if not x then return end

    local model = area.animals[math.random(#area.animals)]
    local hash  = GetHashKey(model)

    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
    end

    if not HasModelLoaded(hash) then return end

    local ped = CreatePed(28, hash, x, y, z, math.random(0, 360), false, true)
    if DoesEntityExist(ped) then
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        TaskWanderStandard(ped, 10.0, 10)
        SetEntityAsMissionEntity(ped, true, true)
        SetModelAsNoLongerNeeded(hash)
        areaAnimals[areaIndex][#areaAnimals[areaIndex] + 1] = ped
    end
end

function CleanAreaAnimals(areaIndex)
    local alive = {}
    for _, ped in ipairs(areaAnimals[areaIndex]) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            alive[#alive + 1] = ped
        else
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
    end
    areaAnimals[areaIndex] = alive
end

function StartSpawning()
    for i, area in ipairs(Config.HuntingAreas) do
        areaAnimals[i] = {}

        CreateThread(function()
            -- Full initial fill
            for _ = 1, area.maxAnimals do
                SpawnAnimalInArea(i, area)
                Wait(100)
            end

            -- Keep topped up aggressively
            while true do
                Wait(area.spawnRate * 1000)
                CleanAreaAnimals(i)
                local current = #areaAnimals[i]
                if current < area.maxAnimals then
                    local toSpawn = area.maxAnimals - current
                    for _ = 1, toSpawn do
                        SpawnAnimalInArea(i, area)
                        Wait(100)
                    end
                end
            end
        end)
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local isDead = args[4]

        if isDead and IsEntityAPed(victim) and not IsPedAPlayer(victim) then
            local model = GetEntityModel(victim)

            for animalModel, animalData in pairs(Config.AnimalValues) do
                if GetHashKey(animalModel) == model then
                    playerInventory[animalModel] = (playerInventory[animalModel] or 0) + 1
                    local total = 0
                    for _, v in pairs(playerInventory) do total = total + v end

                    break
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        nearSellSpot = false

        for _, spot in ipairs(Config.SellSpots) do
            local dist = #(playerCoords - spot.coords)
            if dist <= Config.Settings.SellRadius + 20.0 then
                sleep = 0

                if Config.Settings.EnableMarkers then
                    DrawMarker(
                        Config.Settings.MarkerType,
                        spot.coords.x, spot.coords.y, spot.coords.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        2.0, 2.0, 1.0,
                        Config.Settings.MarkerColor.r,
                        Config.Settings.MarkerColor.g,
                        Config.Settings.MarkerColor.b,
                        Config.Settings.MarkerColor.a,
                        false, true, 2, false, nil, nil, false
                    )
                end

                if dist <= Config.Settings.SellRadius then
                    nearSellSpot    = true
                    currentSellSpot = spot

                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to sell animals")
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 51) then
                        SellAnimals()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function SellAnimals()
    local total = 0
    for _, v in pairs(playerInventory) do total = total + v end

    if total == 0 then
        return
    end

    TriggerServerEvent('hunt:server:sellAnimals', playerInventory)
    playerInventory = {}
end

RegisterCommand('hunt', function()
    TriggerServerEvent('hunt:server:requestData')
    TriggerEvent('hunt:client:openUI')
end, false)

RegisterCommand('huntleaderboard', function()
    TriggerServerEvent('hunt:server:requestLeaderboard')
end, false)

RegisterNetEvent('hunt:client:receiveData', function(data)
    SendNUIMessage({
        action     = 'updateStats',
        data       = data,
        animalCfg  = Config.AnimalValues,
        milestones = Config.MilestoneRewards,
    })
end)

RegisterNetEvent('hunt:client:receiveLeaderboard', function(rows)
    SendNUIMessage({
        action = 'updateLeaderboard',
        rows   = rows,
    })
    TriggerEvent('hunt:client:openUI')
end)

RegisterNetEvent('hunt:client:sellResult', function(result)
    SendNUIMessage({
        action = 'sellResult',
        result = result,
    })
    TriggerServerEvent('hunt:server:requestData')
end)


RegisterNetEvent('hunt:client:openUI', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

AddEventHandler('hunt:client:openUI', function()
    TriggerServerEvent('hunt:server:requestData')
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('requestLeaderboard', function(data, cb)
    TriggerServerEvent('hunt:server:requestLeaderboard')
    cb('ok')
end)
