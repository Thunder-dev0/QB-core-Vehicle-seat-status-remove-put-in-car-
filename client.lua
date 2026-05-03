local ox_target = exports.ox_target
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('thunders:executeAction', function(vehNetId, seatIndex)
    local ped = PlayerPedId()
    
    if seatIndex == -2 then
        -- REMOVE LOGIC
        local vehicle = GetVehiclePedIsIn(ped, true)
        if vehicle == 0 then vehicle = GetVehiclePedIsIn(ped, false) end
        
        -- Force the player out regardless of death state
        ClearPedTasksImmediately(ped)
        TaskLeaveVehicle(ped, vehicle, 16)
        
        -- Fallback: If they are still in the car (common when dead), teleport them out
        SetTimeout(500, function()
            if IsPedInAnyVehicle(ped, false) then
                local coords = GetEntityCoords(ped)
                SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.5, true, false, false, false)
            end
        end)
    else
        -- PUT IN LOGIC
        local vehicle = NetToVeh(vehNetId)
        if DoesEntityExist(vehicle) then
            TaskWarpPedIntoVehicle(ped, vehicle, seatIndex)
        end
    end
end)

-- PUT IN: Target the Player
ox_target:addGlobalPlayer({
    {
        name = 'put_in_veh',
        icon = 'fa-solid fa-car',
        label = 'Put in Vehicle',
        onSelect = function(data)
            local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            local coords = GetEntityCoords(PlayerPedId())
            local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)

            if DoesEntityExist(vehicle) then
                local netId = VehToNet(vehicle)
                for i = -1, 6 do
                    if IsVehicleSeatFree(vehicle, i) then
                        TriggerServerEvent('thunders:syncVehicle', targetId, netId, i)
                        return
                    end
                end
            end
        end
    }
})

-- REMOVE: Target the Vehicle
ox_target:addGlobalVehicle({
    {
        name = 'remove_list',
        icon = 'fa-solid fa-users',
        label = 'Remove Occupant',
        onSelect = function(data)
            local vehicle = data.entity
            local tempOccupants = {}
            local netId = VehToNet(vehicle)

            for i = -1, 6 do
                local occupant = GetPedInVehicleSeat(vehicle, i)
                if occupant ~= 0 and IsPedAPlayer(occupant) then
                    table.insert(tempOccupants, {
                        serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(occupant)),
                        seat = i
                    })
                end
            end

            if #tempOccupants == 0 then return end

            QBCore.Functions.TriggerCallback('thunders:getVehicleNames', function(names)
                local options = {}
                for _, pData in ipairs(tempOccupants) do
                    table.insert(options, {
                        title = names[pData.serverId] or "Unknown",
                        description = (pData.seat == -1 and 'Driver' or 'Seat ' .. pData.seat + 1) .. ' (ID: ' .. pData.serverId .. ')',
                        onSelect = function()
                            TriggerServerEvent('thunders:syncVehicle', pData.serverId, netId, -2)
                        end
                    })
                end

                exports.ox_lib:registerContext({
                    id = 'veh_remove_menu',
                    title = 'Select Player to Remove',
                    options = options
                })
                exports.ox_lib:showContext('veh_remove_menu')
            end, tempOccupants)
        end
    }
})