local inService = false
local activeSpot = false
local tasksRemaining = 0
local spot
local taskZone
local lastLoc

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
    activeSpot = false
    sweepEmote(true)
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
            if taskZone then
                taskZone:remove()
                taskZone = nil
            end
            spot = nil
            DoNotification(('Tasks Remaining: %s'):format(tasksRemaining))
            generateTask()
        end
    end
end

local function serviceLoop()
    generateTask()
    CreateThread(function()
        local ped = cache.ped
        local cs = Config.Zone.start
        while inService do
            local pos = GetEntityCoords(ped)
            if #(pos - cs) > 30.0 and not isPlayerDead() then
                SetEntityCoords(ped, cs)
                DoNotification(('You still have %s tasks left.'):format(tasksRemaining))
            end
            Wait(2000)
        end
    end)
end

function generateTask()
    spot = Config.Zone.spots[math.random(#Config.Zone.spots)]
    while lastLoc == spot do
        spot = Config.Zone.spots[math.random(#Config.Zone.spots)]
        Wait(100)
    end
    taskZone = lib.zones.box({
        coords = vec3(spot.x, spot.y, spot.z),
        size = vec3(2, 2, 2),
        rotation = 0,
        debug = false,
        inside = function()
            if IsControlJustPressed(0, 38) and activeSpot then
                lib.hideTextUI()
                completeTask()
            end
	end,
	onEnter = function()
            lib.showTextUI('**E** - Sweep', {icon = 'broom', position = "left-center"})
	end,
	onExit = function()
            lib.hideTextUI()
	end
    })
    lastLoc = spot
    activeSpot = true
    Wait(500)
    CreateThread(function()
        while activeSpot do
            if spot then
                DrawMarker(21, spot.x, spot.y, spot.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 140, 12, 199, 190, false, true, 2, true, false, false, false)
            end
            Wait(0)
        end
    end)
end

RegisterNetEvent('randol_cs:client:sendtoService', function(taskNumber, New)
    if GetInvokingResource() then return end
    SetEntityCoords(cache.ped, Config.Zone.start)
    inService = true
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
    inService = false
    activeSpot = false
    tasksRemaining = 0
    spot = nil
    lastLoc = nil
    taskZone = nil
    DoNotification('Your community service is now over.', 'success')
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        if taskZone then taskZone:remove() end
	end 
end)

AddEventHandler('randol_cs:onPlayerLogout', function()
    if taskZone then taskZone:remove() end
    activeSpot = false
    spot = nil
    lastLoc = nil
    inService = false
    tasksRemaining = 0
    taskZone = nil
end)
