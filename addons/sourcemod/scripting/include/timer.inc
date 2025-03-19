#if defined _timer_included
 #endinput
#endif
#define _timer_included

#include <sourcemod>
#include <sdktools>

// Utility functions
stock bool IsValidClient(int client, bool bAlive = false) {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    if (!IsClientInGame(client)) return false;
    if (bAlive && !IsPlayerAlive(client)) return false;
    return true;
}

// Global map name storage
stock char g_sCurrentMap[PLATFORM_MAX_PATH];

// Enum definitions to match plugin
enum ZoneType {
    ZONE_NONE = 0,
    ZONE_START,
    ZONE_END,
    ZONE_CHECKPOINT,
    ZONE_STAGE
}

enum LeaderboardType {
    LEADERBOARD_TOTAL_POINTS = 0,
    LEADERBOARD_MAP_COMPLETIONS,
    LEADERBOARD_TIER_TIMES
}

enum ReplayType {
    REPLAY_MAIN_MAP = 0,
    REPLAY_STAGE,
    REPLAY_BONUS,
    REPLAY_PRACTICE
}

// Utility functions for type names
stock void GetReplayTypeName(int type, char[] buffer, int maxlen) {
    switch(type) {
        case 0: strcopy(buffer, maxlen, "None");
        case 1: strcopy(buffer, maxlen, "Normal");
        case 2: strcopy(buffer, maxlen, "Pro");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

stock void GetLeaderboardTypeName(int type, char[] buffer, int maxlen) {
    switch(type) {
        case 0: strcopy(buffer, maxlen, "Global");
        case 1: strcopy(buffer, maxlen, "Map");
        case 2: strcopy(buffer, maxlen, "Tier");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

stock void GetMapTierName(int tier, char[] buffer, int maxlen) {
    switch(tier) {
        case 1: strcopy(buffer, maxlen, "Beginner");
        case 2: strcopy(buffer, maxlen, "Easy");
        case 3: strcopy(buffer, maxlen, "Medium");
        case 4: strcopy(buffer, maxlen, "Hard");
        case 5: strcopy(buffer, maxlen, "Expert");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

// Placeholder methodmaps to resolve undefined symbols
methodmap SurfMapManager {
    public static void LoadMapList() {}
    public static int GetMapTier(const char[] mapname) { return 1; }
    public static void DisplayMapInfo(int client, const char[] mapname) {}
    public static void ListIncompleteMaps(int client) {}
    public static void ListIncompleteStages(int client, const char[] mapname) {}
    public static void ListIncompleteBonuses(int client, const char[] mapname) {}
}

methodmap SurfPlayerManager {
    public static void DisplayPlayerInfo(int client, int target) {}
}

methodmap SurfLeaderboard {
    public static void DisplayLeaderboard(int client, int type) {}
}

methodmap SurfReplaySystem {
    public static bool StartReplay(int client, int type) { return true; }
    public static bool StopReplay(int client) { return true; }
    public static void ListReplays(int client, int type) {}
}

methodmap SurfZones {
    public static void LoadZonesFromMap(const char[] mapname) {}
    public static void CreateZoneConfiguration(const char[] mapname) {}
    public static int GetPlayerCurrentZoneType(int client) { return 0; }
}

methodmap SurfDatabase {
    public static float GetPersonalBest(const char[] mapname, int style) { return 0.0; }
}

// Global instances
stock SurfMapManager g_SurfMapManager;
stock SurfPlayerManager g_SurfPlayerManager;
stock SurfLeaderboard g_SurfLeaderboard;
stock SurfReplaySystem g_SurfReplaySystem;
stock SurfZones g_SurfZones;
stock SurfDatabase g_SurfDatabase;