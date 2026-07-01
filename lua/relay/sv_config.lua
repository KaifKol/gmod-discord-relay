Discord = {
	['webhook'] = "webhook", -- REPLACE THIS
	
	['hookname'] = "Gmod Relay",

	['readChannelID'] = "channelid", -- REPLACE THIS

	['botToken'] = 'bottoken', -- REPLACE THIS

	["botPrefix"] = "!",

	["srvStarted"] = true,

	["srvShutdown"] = true,

	["hideBots"] = true,

	["language"] = "en",

	-- For developers (logs)
	['debug'] = false,

	-- !!!!!!!!Don't touch, meant for transient storage of the commands executed by user.!!!!!!!!
	-- !!!!!!!!If touched WILL lead to the bot breaking!!!!!!!!
	['commands'] = {},
	-- Channel IDs for live channel updates (Discord channel rename feature)
	['channelOnlineID'] = "",  -- Channel to show player count (format: "👥 Онлайн: 15/50")
	['channelStatusID'] = "",  -- Channel to show server status (format: "🟢 Сервер: Онлайн")
	['channelUpdateInterval'] = 60,  -- Update interval in seconds (min 60). Discord rate limit: 2 PATCH per 10 min per channel — actual PATCH sent only on value change.
}
