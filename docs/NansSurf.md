# NansSurf Core Plugin

## Overview
NansSurf is the core plugin for CS2 surf servers, providing essential functionality for surf gameplay mechanics and zone management.

## Features

### Zone System
- **Start Zones**: Marks the beginning of surf runs
- **End Zones**: Marks the completion point of surf runs
- **Checkpoint Zones**: Allows players to save progress points
- **Bonus Zones**: Special areas for bonus challenges
- **Stage Zones**: Supports multi-stage map layouts

### Admin Commands
- `sm_zone`: Opens the zone management menu
- `sm_addzone`: Adds a new zone to the map
- `sm_delzone`: Deletes an existing zone

### Zone Types
1. Start Zone
2. End Zone
3. Checkpoint
4. Bonus Start
5. Bonus End
6. Stage Start
7. Stage End

### Player Tracking
- Tracks player position in zones
- Monitors current stage progress
- Handles bonus area progression
- Provides real-time zone entry/exit events

## Installation

1. Place the plugin in your `addons/sourcemod/plugins` directory
2. Create the following directories:
   - `addons/sourcemod/data/surf/zones`
   - `addons/sourcemod/data/surf/stats`
   - `addons/sourcemod/data/surf/records`

## Configuration
Zones are automatically saved per map in the `data/surf/zones` directory with the format `mapname.zones`.

## Developer Information

### Natives
- `NansSurf_GetSpawnPosition`: Get the spawn position for a player
- `NansSurf_GetZoneCount`: Get the total number of zones
- `NansSurf_GetZonePosition`: Get a zone's position
- `NansSurf_IsInStartZone`: Check if a player is in start zone
- `NansSurf_IsInEndZone`: Check if a player is in end zone
- `NansSurf_GetCurrentStage`: Get player's current stage
- `NansSurf_GetCurrentBonus`: Get player's current bonus level

### Forwards
- `NansSurf_OnPlayerEnterStartZone`
- `NansSurf_OnPlayerEnterEndZone`
- `NansSurf_OnPlayerEnterCheckpoint`
- `NansSurf_OnPlayerEnterStageZone`
- `NansSurf_OnPlayerEnterBonusZone`

## Dependencies
- SourceMod 1.11 or higher
- CS2 Dedicated Server 