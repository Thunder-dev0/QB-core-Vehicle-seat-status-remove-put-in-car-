local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('thunders:syncVehicle', function(targetId, vehNetId, seatIndex)
    if GetPlayerName(targetId) then 
        TriggerClientEvent('thunders:executeAction', targetId, vehNetId, seatIndex)
    end
end)

QBCore.Functions.CreateCallback('thunders:getVehicleNames', function(source, cb, netIds)
    local playerNames = {}
    for _, data in ipairs(netIds) do
        local TPlayer = QBCore.Functions.GetPlayer(data.serverId)
        if TPlayer then
            playerNames[data.serverId] = TPlayer.PlayerData.charinfo.firstname .. " " .. TPlayer.PlayerData.charinfo.lastname
        else
            playerNames[data.serverId] = GetPlayerName(data.serverId)
        end
    end
    cb(playerNames)
end)