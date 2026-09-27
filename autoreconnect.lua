-- Auto Reconnect
-- Tries the current server several times, then falls back to a fresh server.
-- Intended for ordinary connection/teleport failures. It does not bypass bans.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local originalJobId = game.JobId

local SAME_SERVER_TRIES = 5
local RETRY_DELAY = 3

local reconnecting = false
local sameServerAttempts = 0

local function shouldIgnoreMessage(message)
    message = string.lower(tostring(message or ""))

    if string.find(message, "banned", 1, true) then
        return true
    end

    return false
end

local function teleportOnce()
    sameServerAttempts += 1

    if originalJobId ~= "" and sameServerAttempts <= SAME_SERVER_TRIES then
        print(("Reconnect attempt %d/%d: same server"):format(
            sameServerAttempts,
            SAME_SERVER_TRIES
        ))

        return pcall(function()
            TeleportService:TeleportToPlaceInstance(
                placeId,
                originalJobId,
                player
            )
        end)
    end

    print("Same server unavailable. Trying a fresh server...")

    return pcall(function()
        TeleportService:Teleport(placeId, player)
    end)
end

local function reconnectLoop()
    if reconnecting then
        return
    end

    reconnecting = true

    while reconnecting do
        local ok, err = teleportOnce()

        if not ok then
            warn("Reconnect attempt failed:", err)
        end

        task.wait(RETRY_DELAY)
    end
end

TeleportService.TeleportInitFailed:Connect(function(failedPlayer)
    if failedPlayer ~= player then
        return
    end

    task.spawn(reconnectLoop)
end)

GuiService.ErrorMessageChanged:Connect(function(message)
    if not message or message == "" then
        return
    end

    if shouldIgnoreMessage(message) then
        warn("Reconnect disabled for this error:", message)
        return
    end

    warn("Connection error detected:", message)
    task.spawn(reconnectLoop)
end)

print("Auto reconnect loaded.")
