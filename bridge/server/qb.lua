if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetPlyIdentifier(Player)
    return Player.PlayerData.citizenid
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function CheckPoliceJob(Player)
    if Player.PlayerData.job.type == 'leo' then return true end
    return false
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    checkService(src)
end)