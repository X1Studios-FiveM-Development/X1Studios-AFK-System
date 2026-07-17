local lastActivity = GetGameTimer()
local isAFK = false
local afkStart = 0
local showingUI = false

local AFK_TRIGGER = 10 * 60 * 1000 -- 10 minutes
local KICK_TIME = 15 * 60 * 1000   -- 15 minutes total

-- Detect player activity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if IsControlJustPressed(0, 32) or -- W
           IsControlJustPressed(0, 34) or -- A
           IsControlJustPressed(0, 31) or -- S
           IsControlJustPressed(0, 30) or -- D
           IsControlJustPressed(0, 24) or -- Mouse click
           IsPedInAnyVehicle(PlayerPedId(), true)
        then
            lastActivity = GetGameTimer()

            if isAFK then
                isAFK = false
                showingUI = false
                SendNUIMessage({ action = "hide" })
                SetNuiFocus(false, false)
            end
        end

        local currentTime = GetGameTimer()

        if not isAFK and (currentTime - lastActivity) >= AFK_TRIGGER then
            isAFK = true
            afkStart = currentTime
            showingUI = true

            SendNUIMessage({
                action = "show",
                time = 10
            })

            SetNuiFocus(true, true)
        end

        if isAFK then
            local elapsed = currentTime - afkStart
            local remaining = math.ceil((KICK_TIME - elapsed) / 60000)

            if remaining <= 5 and showingUI then
                SendNUIMessage({
                    action = "update",
                    time = remaining
                })
            end

            if elapsed >= KICK_TIME then
                TriggerServerEvent("x1s-afk:kick")
            end
        end
    end
end)

-- NUI callback
RegisterNUICallback("back", function(data, cb)
    isAFK = false
    lastActivity = GetGameTimer()

    SendNUIMessage({ action = "hide" })
    SetNuiFocus(false, false)

    cb("ok")
end)
