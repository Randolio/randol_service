local players = {}
local maxTasks = 50 -- Max amount of tasks a player can be sent for.

local function updateService(src, cid)
    if not players[cid] then return end

    local val = 0

    players[cid].tasksleft -= 1
    val = players[cid].tasksleft

    if val == 0 then
        players[cid] = nil
        MySQL.query.await('DELETE FROM randol_cs WHERE cid = ?', {cid})
        TriggerClientEvent('randol_cs:client:finishService', src)
    else
        MySQL.query.await('UPDATE randol_cs SET tasksleft = ? WHERE cid = ?', {val, cid})
    end

    return val
end

local function releasePlayer(src, ply, cid)
    if not players[cid] then
        return DoNotification(src, 'This person is not in community service.', 'error')
    end
    players[cid] = nil
    MySQL.query.await('DELETE FROM randol_cs WHERE cid = ?', {cid})
    TriggerClientEvent('randol_cs:client:finishService', ply)
    DoNotification(src, 'You released them from community service.', 'success')
end

function checkService(src)
    local Player = GetPlayer(src)
    if not Player then return end

    local cid = GetPlyIdentifier(Player)

    if not players[cid] then return end
    SetTimeout(2000, function()
        local tasks = players[cid].tasksleft
        TriggerClientEvent('randol_cs:client:sendtoService', src, tasks, false)
    end)
end

lib.callback.register('randol_cs:server:updateService', function(source)
    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)
    if not players[cid] then return false end
    local tasksLeft = updateService(src, cid)
    return tasksLeft
end)

lib.addCommand('cs', {
    help = 'Send to community service.',
    params = {
        { name = 'target', type = 'playerId', help = 'ID of the suspect.', },
        { name = 'tasks', type = 'number', help = 'Number of tasks to complete', },
    }
}, function(source, args)
    local src = source
    local Player = GetPlayer(src)
    local isPolice = CheckPoliceJob(Player)
    if not Player or not isPolice then return end

    local Suspect = GetPlayer(args.target)
    if not args.target or not Suspect then return end

    local cid = GetPlyIdentifier(Suspect)
    local name = GetCharacterName(Suspect)

    local tasks = args.tasks
    if tasks > 0 and tasks <= maxTasks then
        if players[cid] then
            return DoNotification(src, "Suspect has an outstanding community service to finish. Why aren't they there?", "error")
        end
        players[cid] = { tasksleft = tasks }
        MySQL.insert.await('INSERT INTO randol_cs (cid, tasksleft) VALUE (?, ?)', {cid, tasks})
        TriggerClientEvent('randol_cs:client:sendtoService', args.target, tasks, true)
        DoNotification(src, ('You sent %s to community service for %s tasks.'):format(name, tasks), 'success')
    else
        return DoNotification(src, ('Must be between 1-%s.'):format(maxTasks), 'error')
    end
end)

lib.addCommand('removecs', {
    help = 'Release from community service.',
    params = {
        { name = 'target', type = 'playerId', help = 'ID of the suspect.', },
    }
}, function(source, args)
    local src = source
    local Player = GetPlayer(src)
    local isPolice = CheckPoliceJob(Player)
    if not Player or not isPolice then return end

    local Suspect = GetPlayer(args.target)
    if not args.target or not Suspect then return end

    local cid = GetPlyIdentifier(Suspect)

    releasePlayer(src, args.target, cid)
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    local result = MySQL.query.await('SELECT * from randol_cs', {})
    if result and result[1] then
        for i = 1, #result do
            local v = result[i]
            players[v.cid] = { 
                tasksleft = v.tasksleft 
            }
        end
    end

    local players = GetPlayers()
    if #players > 0 then
        for i = 1, #players do
            local src = tonumber(players[i])
            checkService(src)
        end
    end
end)