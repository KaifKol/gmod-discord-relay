# Discord Relay for Garry's Mod

Bidirectional chat relay between your Garry's Mod server and a Discord channel.  
Also supports **live Discord channel rename** — display server player count and status on voice/text channels in real time. Data is sourced from native GMod APIs, no external dependencies.

## Features

- **Chat Mirroring** — GMod ↔ Discord: every message in the game chat appears in your Discord channel and vice versa.
- **Rich Embeds** — player joins, leaves, spawns, server start/shutdown events with colored embed cards.
- **Reply Handling** — Discord reply/thread context is included as `@mention` in GMod output.
- **Media Forwarding** — attached images and files from Discord are posted as direct links in GMod chat.
- **Live Channel Names** — rename Discord channels to show current online count and server status (online/offline), updated every 60 seconds with rate-limit-safe change detection. Uses `player.GetAll()` and `game.MaxPlayers()` internally.
- **Command System** — extensible Discord bot commands (built-in: `!status`, `!ping`).
- **Multi-language** — English and Russian translation support, extensible.

## Screenshots

| Discord chat | GMod chat |
|:---:|:---:|
| ![Discord](preview/1.png) | ![GMod](preview/2.png) |

## Requirements

- **[GWSockets](https://github.com/FredyH/GWSockets/releases/)** — WebSocket client for the Discord Gateway API.
- **[CHTTP](https://github.com/timschumi/gmod-chttp/releases)** — asynchronous HTTP requests with custom methods and headers (Discord REST API).

Both are binary modules. Place the `.dll` / `.so` files in `garrysmod/lua/bin/`.

## Installation

### 1. Install dependencies

Download the latest releases of `GWSockets` and `CHTTP` and copy the binaries into your server's `garrysmod/lua/bin/` directory (create it if it doesn't exist).

> **Note:** GWSockets and CHTTP are **server-side only**. Clients do not need them.

### 2. Install the addon

Clone or download this repository into `garrysmod/addons/gmod-discord-relay/`.  
The final path should look like:

```
garrysmod/addons/gmod-discord-relay/lua/autorun/gmod_discord_relay.lua
garrysmod/addons/gmod-discord-relay/lua/relay/sv_config.lua
...
```

### 3. Configure the bot

Edit the following files:

#### `lua/relay/sv_config.lua` (server configuration)

| Field | Description |
|-------|-------------|
| `webhook` | Discord webhook URL for sending messages to your channel |
| `readChannelID` | ID of the Discord channel the bot reads messages from |
| `botToken` | Your Discord bot token |
| `botPrefix` | Command prefix (default `!`) |
| `srvStarted` | Send an embed when the server starts (`true`/`false`) |
| `srvShutdown` | Send an embed when the server shuts down (`true`/`false`) |
| `hideBots` | Hide bot messages in GMod chat (`true`/`false`) |
| `language` | `"en"` for English, `"ru"` for Russian |
| `channelOnlineID` | *(optional)* Discord channel ID for the player count display |
| `channelStatusID` | *(optional)* Discord channel ID for the server status display |
| `channelUpdateInterval` | How often to check live data (seconds, minimum `60`) |

#### `lua/relay/cl_config.lua` (client configuration)

| Field | Description |
|-------|-------------|
| `prefix` | Chat prefix text (default `"Discord"`) |
| `prefixClr` | Chat prefix color |

### 4. Create a Discord bot

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications) and create a new application.
2. Under **Bot**, create a bot and copy its token into `sv_config.botToken`.
3. Under **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Permissions: `Send Messages`, `Read Message History`, `View Channels`, `Manage Channels` (required for channel rename), `Embed Links`
4. Use the generated URL to add the bot to your server.
5. Make sure the bot has access to the channels you want it to read from and write to.

**Channel rename permissions:**

![Permissions step 1](preview/perm1.png)
![Permissions step 2](preview/perm2.png)

If you use the live channel rename feature, the bot also needs the `Manage Channels` permission on the channels specified in `channelOnlineID` / `channelStatusID`.

### 5. Restart the server

After everything is configured, restart your GMod server. You should see:

```
----------------------
DISCORD RELAY LOADED!
----------------------
```

## Live Channel Names

When `channelOnlineID` and/or `channelStatusID` are set, the bot uses native GMod APIs (`player.GetAll()`, `game.MaxPlayers()`) to build live data and renames the specified Discord channels via the REST API. No external JSON file or loading screen addon required.

**Format (language-dependent):**

| Channel | English | Russian |
|---------|---------|---------|
| Online count | `👥 Online: 12/64` | `👥 Онлайн: 12/64` |
| Status (online) | `🟢 Server: Online` | `🟢 Сервер: Онлайн` |
| Status (offline) | `🔴 Server: Offline` | `🔴 Сервер: Офлайн` |

**Rate limit safety:** The bot checks every `channelUpdateInterval` seconds but only sends a PATCH request when the channel name would actually change. This respects Discord's per-channel rate limit of 2 PATCH requests per 10 minutes.

## Commands

Type `!status` or `!ping` in your Discord channel to get server info.

You can add custom commands by placing Lua files in `lua/relay/commands/`.  
Each file registers its handler in `Discord.commands["commandname"]`.

## Translation

Language strings are stored in `lua/relay/translations/` and selected by `Discord.language`.  
To add a new language, copy `en.lua`, translate the values, and update the `language` selection logic in `gmod_discord_relay.lua`.

## File Structure

```
gmod-discord-relay/
├── lua/
│   ├── autorun/
│   │   └── gmod_discord_relay.lua    # Entry point
│   └── relay/
│       ├── sv_config.lua             # Server-side configuration
│       ├── sv_msgSend.lua            # Sending messages to Discord (webhook)
│       ├── sv_msgGet.lua             # Receiving from Discord (WebSocket gateway)
│       ├── sv_liveChannels.lua       # Live channel rename logic (native GMod APIs)
│       ├── cl_config.lua             # Client-side configuration
│       ├── cl_msgReceive.lua         # Client message display
│       ├── commands/
│       │   ├── status.lua            # !status command
│       │   └── ...                   # Your custom commands
│       └── translations/
│           ├── en.lua                # English strings
│           └── ru.lua                # Russian strings
└── preview/                          # Screenshots
```
