#if defined _timer_included
 #endinput
#endif
#define _timer_included

#include <sourcemod>
#include <sdktools>

// Common timer-related definitions and forward declarations
enum TimerType {
    TIMER_NONE = 0,
    TIMER_NORMAL,
    TIMER_REPEAT,
    TIMER_HIGHTASK
}

// Basic timer function
native Handle CreateTimer(float interval, Function func, any data = 0, int flags = 0);
native bool KillTimer(Handle timer);

// Client utility functions
stock bool IsValidClient(int client, bool bAlive = false) {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    if (!IsClientInGame(client)) return false;
    if (bAlive && !IsPlayerAlive(client)) return false;
    return true;
}

// Compatibility print to chat function
#if !defined _colors_included
stock void CPrintToChat(int client, const char[] message, any ...) {
    char buffer[256];
    VFormat(buffer, sizeof(buffer), message, 3);
    PrintToChat(client, buffer);
}
#endif

// Global map name storage
stock char g_sCurrentMap[PLATFORM_MAX_PATH];

// Utility function to get current map name
stock void GetCurrentMapName() {
    GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
}

// Replay type name function (placeholder)
stock void GetReplayTypeName(int type, char[] buffer, int maxlen) {
    switch(type) {
        case 0: strcopy(buffer, maxlen, "None");
        case 1: strcopy(buffer, maxlen, "Normal");
        case 2: strcopy(buffer, maxlen, "Pro");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

// Leaderboard type name function (placeholder)
stock void GetLeaderboardTypeName(int type, char[] buffer, int maxlen) {
    switch(type) {
        case 0: strcopy(buffer, maxlen, "Global");
        case 1: strcopy(buffer, maxlen, "Map");
        case 2: strcopy(buffer, maxlen, "Tier");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

// Map tier name function (placeholder)
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

// Methodmap for surf map manager (placeholder)
methodmap SurfMapManager {
    public SurfMapManager() {
        return view_as<SurfMapManager>(0);
    }

    public bool LoadMapList() {
        return true;
    }

    public int GetMapTier(const char[] mapname) {
        return 1;
    }
}

// Methodmap for surf replay system (placeholder)
methodmap SurfReplaySystem {
    public SurfReplaySystem() {
        return view_as<SurfReplaySystem>(0);
    }

    public bool StartReplay(int client, int type) {
        return true;
    }

    public bool StopReplay(int client) {
        return true;
    }
}

// Global instances (placeholders)
stock SurfMapManager g_SurfMapManager;
stock SurfReplaySystem g_SurfReplaySystem; 