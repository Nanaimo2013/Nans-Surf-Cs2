# NansSurf Discord Plugin

## Overview
NansSurf Discord provides seamless integration between your CS2 surf server and Discord, offering real-time updates, statistics, and server information through a comprehensive API.

## Features

### Real-time Updates
- **Record Announcements**: Automatically announces new records
- **Player Achievements**: Posts player milestones and achievements
- **Server Status**: Live server status updates

### Player Data Integration
- **Player Stats**: Access to complete player statistics
- **Ranking Information**: Real-time rank tracking
- **Personal Bests**: Track and display personal best times
- **Online Status**: Monitor player online status

### Server Information
- **Map Information**: Current map and map details
- **Player Count**: Real-time player count tracking
- **Active Players**: Track currently active surfers
- **Server Status**: General server information

### Leaderboard Integration
- **Top Players**: Access to server's top players
- **Recent Records**: Track recent record completions
- **Map Records**: Access to map-specific records
- **Global Rankings**: Server-wide ranking system

## API Endpoints

### Player Data
- `GetPlayerStats`: Complete player statistics
- `GetPlayerRank`: Current player ranking
- `GetPlayerBestTime`: Best times for maps
- `GetPlayerTotalRuns`: Total completed runs
- `GetPlayerName`: Player name information
- `IsPlayerOnline`: Check player online status

### Map Data
- `GetMapRecord`: Current map record
- `GetMapRecordHolder`: Record holder information
- `GetMapCompletions`: Total map completions
- `GetMapAverageTime`: Average completion time

### Server Data
- `GetOnlinePlayerCount`: Current player count
- `GetActivePlayerCount`: Active player count
- `GetTotalRankedPlayers`: Total ranked players
- `GetCurrentMap`: Current map information

### Leaderboard Data
- `GetTopTimes`: Best times leaderboard
- `GetRecentRecords`: Recent record completions
- `GetPlayerPosition`: Player ranking position

## Installation

1. Place the plugin in your `addons/sourcemod/plugins` directory
2. Configure Discord webhook URLs in the plugin configuration
3. Ensure all required directories exist

## Dependencies
- NansSurf Core Plugin
- NansSurf Stats Plugin
- SourceMod 1.11 or higher
- CS2 Dedicated Server

## Developer Information

### Natives
All API endpoints are available as natives for other plugins to use.

### Recent Records System
- Stores up to 100 recent records
- Includes player name, time, rank, and timestamp
- Supports both personal bests and server records 