--[[
    Discord Live Channel Updater
    Periodically renames Discord channels via REST API (PATCH /channels/:id)
    to show live server status (player count, online/offline).

    Data is sourced from native GMod APIs — no external JSON dependency.

    Configuration (sv_config.lua):
        Discord.channelOnlineID   — channel to show player count
        Discord.channelStatusID   — channel to show server online/offline
        Discord.channelUpdateInterval — seconds between checks (default 60)
]]

-- Cache last sent name per channel to avoid redundant PATCH requests.
local lastNames = {}

-- Build live data from native GMod APIs.
local function getLiveData()
    local players = player.GetAll()
    return {
        players = players,
        maxPlayers = game.MaxPlayers(),
    }
end

-- Send a PATCH request to Discord REST API to rename one channel.
-- Skips if the name hasn't changed since last successful send.
-- Uses CHTTP (already required in sv_msgSend.lua).
local function updateChannelName(channelID, newName)
    if not channelID or channelID == "" then return end

    -- Skip if the name is already the same as what we last sent
    if lastNames[channelID] == newName then return end

    CHTTP({
        ["failed"] = function(msg)
            print("[Discord] [LiveChannels] Failed to update " .. channelID .. ": " .. tostring(msg))
        end,
        ["success"] = function(code, body, headers)
            if Discord.debug then
                print("[Discord] [LiveChannels] " .. channelID .. " → \"" .. newName .. "\" (HTTP " .. code .. ")")
            end
            if code == 200 or code == 201 then
                lastNames[channelID] = newName
            end
            if code == 429 then
                print("[Discord] [LiveChannels] Rate-limited on " .. channelID .. ", will retry next cycle")
            end
        end,
        ["method"] = "PATCH",
        ["url"] = "https://discord.com/api/v10/channels/" .. channelID,
        ["body"] = util.TableToJSON({ ["name"] = newName }),
        ["headers"] = {
            ["Authorization"] = "Bot " .. Discord.botToken,
            ["Content-Type"] = "application/json",
        },
        ["type"] = "application/json",
    })
end

-- Core update: get live data, build channel names, send patches.
local function updateLiveChannels()
    local liveData = getLiveData()

    -- Player-count channel
    if Discord.channelOnlineID and Discord.channelOnlineID ~= "" then
        local playerCount = #liveData.players
        local maxPlayers = liveData.maxPlayers
        updateChannelName(Discord.channelOnlineID, string.format(DiscordString.channelOnline, playerCount, maxPlayers))
    end

    -- Server-status channel
    if Discord.channelStatusID and Discord.channelStatusID ~= "" then
        updateChannelName(Discord.channelStatusID, DiscordString.channelStatusOnline)
    end
end

-- ── Timer ──────────────────────────────────────────────────────────────
local interval = math.max(Discord.channelUpdateInterval or 60, 60)
timer.Create("!!discord_live_channels", interval, 0, updateLiveChannels)

-- First run after a short delay so everything has initialised
timer.Simple(10, updateLiveChannels)

-- ── Shutdown hook ──────────────────────────────────────────────────────
-- Best-effort attempt to mark channels as offline before server stops.
-- NOTE: the HTTP request may not complete before the process exits.
hook.Add("ShutDown", "!!discord_channels_shutdown", function()
    if Discord.channelStatusID and Discord.channelStatusID ~= "" then
        updateChannelName(Discord.channelStatusID, DiscordString.channelStatusOffline)
    end
    if Discord.channelOnlineID and Discord.channelOnlineID ~= "" then
        updateChannelName(Discord.channelOnlineID, string.format(DiscordString.channelOnline, 0, 0))
    end
end)
