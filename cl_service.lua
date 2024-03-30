local Config = lib.require('config')
local activeSpot, showText = false
local spot, taskZone, lastLoc
local tasksRemaining = 0

local function sweepEmote(bool)
    local model = `prop_tool_broom`
    if bool then
        lib.requestAnimDict('anim@amb@drug_field_workers@rake@male_a@base', 2000)
        lib.requestModel(model, 2000)
        BROOM_PROP = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(BROOM_PROP, cache.ped, GetPedBoneIndex(cache.ped, 28422), -0.010000, 0.040000, -0.030000, 0.000000, 0.000000, 0.000000, true, false, false, false, 2, true)
        TaskPlayAnim(cache.ped, 'anim@amb@drug_field_workers@rake@male_a@base', 'base', 3.0, 3.0, -1, 01, 0, 0, 0, 0)
        SetModelAsNoLongerNeeded(model)
    else
        ClearPedTasks(cache.ped)
        if DoesEntityExist(BROOM_PROP) then
            DetachEntity(BROOM_PROP, true, false)
            DeleteEntity(BROOM_PROP)
        end
    end
end

local function completeTask()
    activeSpot, showText = false
    sweepEmote(true)
    if taskZone then taskZone:remove() taskZone = nil end
    if lib.progressCircle({
        duration = 8000,
        position = 'bottom',
        label = 'Being a good civilian..',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then
        sweepEmote(false)
        tasksRemaining = lib.callback.await('randol_cs:server:updateService', false)
        if tasksRemaining > 0 then
            DoNotification(('Tasks Remaining: %s'):format(tasksRemaining))
            generateTask()
        end
    end
end

local function serviceLoop()
    generateTask()
    CreateThread(function()
        local ped = cache.ped
        local cs = Config.start
        while LocalPlayer.state.inService do
            local pos = GetEntityCoords(ped)
            if #(pos - cs) > 30.0 and not isPlyDead() then
                SetEntityCoords(ped, cs)
                DoNotification(('You still have %s tasks left.'):format(tasksRemaining))
            end
            Wait(2000)
        end
    end)
end

function generateTask()
    local spot
    repeat
        spot = Config.spots[math.random(#Config.spots)]
    until spot ~= lastLoc
    
    taskZone = lib.points.new({ 
        coords = vec3(spot.x, spot.y, spot.z), 
        distance = 60, 
        nearby = function(point)
            DrawMarker(21, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 140, 12, 199, 190, false, true, 2, true, false, false, false)
            if point.isClosest and point.currentDistance <= 1.5 then
                if not showText then
                    showText = true
                    lib.showTextUI('**E** - Sweep', {icon = 'broom', position = "left-center"})
                end
                if IsControlJustPressed(0, 38) and activeSpot then
                    lib.hideTextUI()
                    completeTask()
                end
            elseif showText then
                showText = false
                lib.hideTextUI()
            end
        end, 
    })

    lastLoc = spot
    activeSpot = true
end

RegisterNetEvent('randol_cs:client:sendtoService', function(taskNumber, New)
    if GetInvokingResource() then return end
    SetEntityCoords(cache.ped, Config.start)
    LocalPlayer.state.inService = true
    tasksRemaining = tonumber(taskNumber)
    if New then
        DoNotification(('You were sentenced to community service for %s tasks.'):format(tasksRemaining))
    else
        DoNotification(('You still have %s tasks of community service to finish.'):format(tasksRemaining))
    end
    serviceLoop()
end)

RegisterNetEvent('randol_cs:client:finishService', function()
    if GetInvokingResource() then return end
    activeSpot = false
    LocalPlayer.state.inService = false
    spot, taskZone, lastLoc = nil
    tasksRemaining = 0
    DoNotification('Your community service is now over.', 'success')
    SetEntityCoords(cache.ped, Config.finish)
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
        if taskZone then taskZone:remove() end
    end 
end)

AddEventHandler('randol_cs:onPlayerLogout', function()
    if taskZone then taskZone:remove() end
    LocalPlayer.state.inService = false
    activeSpot = false
    spot, taskZone, lastLoc = nil
    tasksRemaining = 0
end)
