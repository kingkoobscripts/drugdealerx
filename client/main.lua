local isSelling = false
local currentBuyer = nil
local buyerVehicle = nil

--- UI Logic
local function toggleUI(show)
    if show then
        local stats = lib.callback.await("drugdealerx:server:getStats", false)
        local leaderboard = lib.callback.await("drugdealerx:server:getLeaderboard", false)
        
        SendNUIMessage({
            action = "open",
            data = { 
                reputation = stats.reputation,
                totalSold = stats.total_sold,
                totalValue = stats.total_value,
                leaderboard = leaderboard
            }
        })
        SetNuiFocus(true, true)
    else
        SendNUIMessage({ action = "close" })
        SetNuiFocus(false, false)
    end
end

RegisterNUICallback("close", function(_, cb)
    toggleUI(false)
    cb("ok")
end)

RegisterCommand("drugstats", function()
    toggleUI(true)
end)

--- Drug Effects
RegisterNetEvent("drugdealerx:client:useDrug", function(effect)
    local ped = PlayerPedId()
    if lib.progressBar({ duration = 2000, label = "Consuming...", useWhileDead = false, canCancel = true }) then
        if effect == "high_weed" then
            SetEntityHealth(ped, GetEntityHealth(ped) + 20)
            ShakeGameplayCam("DRUNK_SHAKE", 1.5)
        elseif effect == "high_meth" then
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.2)
            Wait(15000)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        elseif effect == "high_coke" then
            RestorePlayerStamina(PlayerId(), 1.0)
            AnimpostfxPlay("DrugsMichaelAliensFight", 0, true)
            Wait(10000)
            AnimpostfxStop("DrugsMichaelAliensFight")
        end
        Wait(10000)
        ShakeGameplayCam("DRUNK_SHAKE", 0.0)
    end
end)

--- Picking System
CreateThread(function()
    for i, loc in ipairs(Config.PickLocations) do
        local targetParams = {
            options = {
                {
                    icon = "fas fa-leaf",
                    label = "Search " .. loc.label,
                    action = function()
                        if lib.progressBar({
                            duration = loc.time or 12000,
                            label = "Searching " .. loc.label .. "...",
                            useWhileDead = false,
                            canCancel = true,
                            anim = { dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", clip = "weed_stand_check_v2_inspect_v2_pa" },
                            disable = { move = true, car = true, mouse = false, combat = true }
                        }) then
                            TriggerServerEvent("drugdealerx:server:pickDrug", i)
                        end
                    end
                }
            },
            distance = 2.0
        }
        
        if GetResourceState("ox_target") == "started" then
            exports.ox_target:addBoxZone({
                coords = loc.coords,
                size = vec3(2, 2, 2),
                rotation = 0,
                options = targetParams.options
            })
        else
            exports["qb-target"]:AddBoxZone("drugpick_"..i, loc.coords, 2.0, 2.0, { name="drugpick_"..i, heading=0, debugPoly=false, minZ=loc.coords.z-1, maxZ=loc.coords.z+1 }, targetParams)
        end
    end
end)

--- NPC Delivery
local function summonBuyer()
    if isSelling then return end
    
    local canSell = lib.callback.await("drugdealerx:server:canSell", false)
    if not canSell then
        Bridge.Notify(nil, Config.Messages.not_enough_police, "error")
        return
    end

    isSelling = true
    Bridge.Notify(nil, Config.Messages.delivery_incoming, "inform")

    local playerCoords = GetEntityCoords(PlayerPedId())
    local found, spawnPos, heading = GetClosestVehicleNodeWithHeading(playerCoords.x + math.random(-80, 80), playerCoords.y + math.random(-80, 80), playerCoords.z, 1, 3.0, 0)

    local model = `baller`
    lib.requestModel(model)
    buyerVehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, false)
    
    local pedModel = `a_m_y_stbla_02`
    lib.requestModel(pedModel)
    currentBuyer = CreatePedInsideVehicle(buyerVehicle, 4, pedModel, -1, true, false)

    TaskVehicleDriveToCoord(currentBuyer, buyerVehicle, playerCoords.x, playerCoords.y, playerCoords.z, 13.0, 0, model, 786603, 5.0, 1)
    
    CreateThread(function()
        while DoesEntityExist(currentBuyer) do
            local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(buyerVehicle))
            if dist < 12.0 and GetEntitySpeed(buyerVehicle) < 1.0 then
                TaskLeaveVehicle(currentBuyer, buyerVehicle, 0)
                TaskGoToEntity(currentBuyer, PlayerPedId(), -1, 2.0, 1.0, 1073741824, 0)
                break
            end
            if dist > 150.0 then
                cleanupBuyer(true)
                return
            end
            Wait(1000)
        end

        local sellOptions = {
            {
                label = "Sell Single Order",
                icon = "fas fa-hand-holding-dollar",
                action = function()
                    TriggerServerEvent("drugdealerx:server:processSale", false)
                    cleanupBuyer()
                end
            },
            {
                label = "Sell Bulk Order (Bonus!)",
                icon = "fas fa-box",
                action = function()
                    TriggerServerEvent("drugdealerx:server:processSale", true)
                    cleanupBuyer()
                end
            }
        }

        if GetResourceState("ox_target") == "started" then
            exports.ox_target:addLocalEntity(currentBuyer, sellOptions)
        else
            exports["qb-target"]:AddTargetEntity(currentBuyer, { options = sellOptions, distance = 2.0 })
        end
    end)
end

function cleanupBuyer(immediate)
    if not currentBuyer then return end
    if not immediate then
        TaskEnterVehicle(currentBuyer, buyerVehicle, -1, -1, 1.0, 1, 0)
        TaskVehicleDriveWander(currentBuyer, buyerVehicle, 20.0, 786603)
        Wait(10000)
    end
    DeleteEntity(currentBuyer)
    DeleteEntity(buyerVehicle)
    isSelling = false
end

RegisterCommand("calldealer", function()
    summonBuyer()
end)

RegisterNetEvent("drugdealerx:client:policeAlert", function(coords)
    if Bridge.GetJob() == Config.PoliceJobName then
        lib.notify({ title = "911 Dispatch", description = Config.Messages.police, type = "inform" })
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 161)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 1)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Suspicious Activity")
        EndTextCommandSetBlipName(blip)
        Wait(30000)
        RemoveBlip(blip)
    end
end)