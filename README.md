# Obby Checkpoint System

A Luau module for Roblox obby games that provides checkpoint and respawn functionality with anti-skip protection and per-player data, without memory leaks.

## Installation

1. Place `ObbyCheckpoint.lua` as a ModuleScript in `ReplicatedStorage` (or `ServerScriptService`).
2. Place `config.json` alongside it (optional, but recommended for configuration).
3. In a server Script, require the module and create an instance:

```lua
local ObbyCheckpoint = require(game.ReplicatedStorage.ObbyCheckpoint)
local checkpointSystem = ObbyCheckpoint.new({
    checkpointTag = "Checkpoint",
    respawnDelay = 0.5,
    antiSkip = true,
    debug = false,
})

-- Later, to clean up:
-- checkpointSystem:Destroy()
```

## Checkpoint Setup

- Each checkpoint part must have a `NumberValue` attribute named `CheckpointNumber` (e.g., 1, 2, 3...).
- The system detects when a player's HumanoidRootPart touches a part with this attribute.
- Anti-skip ensures players must touch checkpoints in order (1, then 2, etc.).
- When a player respawns, they are teleported to the last checkpoint they touched.

## Configuration Parameters (config.json)

- `checkpointTag` (string): Attribute name used to identify checkpoint number (default: "Checkpoint" — note: actual attribute read is "CheckpointNumber").
- `respawnDelay` (number): Delay before respawn logic (default: 0.5).
- `antiSkip` (boolean): Enforce sequential checkpoint order (default: true).
- `spawnPartName` (string): Name of the initial spawn part (default: "SpawnLocation").
- `debug` (boolean): Enable debug prints (default: false).

## API

- `ObbyCheckpoint.new(config)` — Creates a new checkpoint system instance.
- `instance:GetPlayerCheckpoint(player)` — Returns the current checkpoint number for a player.
- `instance:SetPlayerCheckpoint(player, number)` — Manually sets a player's checkpoint.
- `instance:Destroy()` — Cleans up all connections and player data. Call this before removing the module.

## Limitations

- Checkpoint detection uses `Touched` events, which may fire multiple times; only higher checkpoint numbers are accepted.
- Anti-skip expects checkpoints numbered sequentially starting from 1.
- The system does not automatically respawn players; it only teleports on character spawn.
- No built-in UI or visual feedback.
- The module assumes a standard Roblox character with Humanoid and HumanoidRootPart.
- `config.json` is for reference; in Roblox you typically pass a Lua table to `.new()`.

## Memory Leak Prevention

All connections are stored per-player and in a central list. Calling `:Destroy()` disconnects everything and clears tables. PlayerRemoving also cleans up per-player connections.
