if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function GetPlayer(id)
    return ESX.GetPlayerFromId(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('esx:showNotification', src, text, nType)
end

function GetPlyIdentifier(xPlayer)
    return xPlayer.identifier
end

function GetCharacterName(xPlayer)
    return xPlayer.getName()
end

function CheckPoliceJob(xPlayer)
     -- Not sure if ESX have job types so just put police jobs in this table.
    local jobs = { police = true}
    if jobs[xPlayer.job.name] then return true end
    return false
end

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    checkOnLoad(playerId)
end)