local Config = {
    TimeUntilAFK    = 10 * 60 * 1000,
    TimeUntilKick   = 10  * 60 * 1000,
    WatchInterval   = 500,
    IgnoreInVehicle = false,
    LookThreshold   = 0.0035,
}

local ActivityControls = {
    [32] = true, -- Move Forward (W)
    [33] = true, -- Move Back (S)
    [34] = true, -- Move Left (A)
    [35] = true, -- Move Right (D)
    [21] = true, -- Sprint
    [22] = true, -- Jump
    [23] = true, -- Enter/Exit vehicle
    [24] = true, -- Attack / LMB
    [25] = true, -- Aim / RMB
    [44] = true, -- Cover
    [45] = true, -- Reload
}

local lastActivity = GetGameTimer()
local isAFK = false
local afkShownAt = 0
local kicked = false

local function ResetActivity()
    lastActivity = GetGameTimer()
end

local function HideAfkUI()
    isAFK = false
    kicked = false
    SendNUIMessage({ action = "hide" })
    SetNuiFocus(false, false)
end

CreateThread(function()
    while true do
        Wait(0)

        local active = false

        if Config.IgnoreInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
            active = true
        else
            for control in pairs(ActivityControls) do
                if IsControlPressed(0, control) then
                    active = true
                    break
                end
            end

            if not active then
                local lookLR = GetDisabledControlNormal(0, 1)
                local lookUD = GetDisabledControlNormal(0, 2)
                if math.abs(lookLR) > Config.LookThreshold or math.abs(lookUD) > Config.LookThreshold then
                    active = true
                end
            end
        end

        if active then
            ResetActivity()

            if isAFK then
                HideAfkUI()
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.WatchInterval)

        local now = GetGameTimer()
        local idleFor = now - lastActivity

        if not isAFK and idleFor >= Config.TimeUntilAFK then
            isAFK = true
            afkShownAt = now
            kicked = false

            SendNUIMessage({
                action    = "show",
                remaining = math.floor(Config.TimeUntilKick / 1000),
                total     = math.floor(Config.TimeUntilKick / 1000),
            })

            SetNuiFocus(true, true)

        elseif isAFK then
            local elapsedSinceShown = now - afkShownAt
            local remaining = math.max(0, math.ceil((Config.TimeUntilKick - elapsedSinceShown) / 1000))

            SendNUIMessage({
                action    = "update",
                remaining = remaining,
                total     = math.floor(Config.TimeUntilKick / 1000),
            })

            if elapsedSinceShown >= Config.TimeUntilKick and not kicked then
                kicked = true
                TriggerServerEvent("x1s-afk:kick")
            end
        end
    end
end)

RegisterNUICallback("back", function(data, cb)
    HideAfkUI()
    ResetActivity()
    cb("ok")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
