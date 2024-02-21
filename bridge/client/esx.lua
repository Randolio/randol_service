if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

PlayerData = {}

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    table.wipe(PlayerData)
    TriggerEvent('randol_cs:onPlayerLogout')
end)

AddEventHandler('esx:setPlayerData', function(key, value)
	PlayerData[key] = value
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not ESX.PlayerLoaded then return end

    PlayerData = ESX.PlayerData
end)

function isPlyDead()
    return PlayerData.dead
end

function DoNotification(text, nType)
    ESX.ShowNotification(text, nType)
end
