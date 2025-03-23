# NansSurf Stats Plugin

## Overview
NansSurf Stats is a comprehensive statistics tracking system for CS2 surf servers, providing detailed player performance metrics and record-keeping functionality.

## Features

### Player Statistics
- **Total Runs**: Tracks the number of completed runs per player
- **Best Times**: Records personal best times for each map
- **Player Ranking**: Global ranking system based on performance
- **Last Seen**: Tracks player activity dates

### Map Records
- **Global Records**: Tracks best times for each map
- **Record History**: Maintains historical data of map completions
- **Record Holders**: Keeps track of record holders per map

### Real-time Tracking
- Automatic stats loading on player connect
- Immediate stats saving on disconnect
- Real-time rank updates
- Performance monitoring during gameplay

### Ranking System
- Global player rankings up to 1000 ranks
- Dynamic rank updates based on performance
- Competitive ranking system

## Installation

1. Place the plugin in your `addons/sourcemod/plugins` directory
2. Ensure the following directories exist:
   - `addons/sourcemod/data/surf/stats`
   - `addons/sourcemod/data/surf/records`

## Data Storage
- Player stats are stored in individual files: `data/surf/stats/<steamid>.stats`
- Map records are stored in: `data/surf/records/<mapname>.records`

## Developer Information

### Natives
- `NansSurfStats_GetTotalRuns`: Get player's total completed runs
- `NansSurfStats_GetBestTime`: Get player's best time on current map
- `NansSurfStats_GetRank`: Get player's global rank
- `NansSurfStats_GetTotalRankedPlayers`: Get total number of ranked players
- `NansSurfStats_SubmitTime`: Submit a new completion time

### Forwards
- `NansSurfStats_OnStatsLoaded`: Called when player stats are loaded
- `NansSurfStats_OnRunComplete`: Called when a player completes a run

## Dependencies
- NansSurf Core Plugin
- SourceMod 1.11 or higher
- CS2 Dedicated Server 