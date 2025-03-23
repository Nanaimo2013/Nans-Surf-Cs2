#include <sourcemod>
#include <NansSurf>
#include <NansSurfStats>
#include <NansSurfTimer>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define MAX_RECENT_RECORDS 100

public Plugin myinfo = {
    name = "Nans Surf Discord API",
    author = "Nanaimo_2013",
    description = "API for Discord integration with CS2 Surf servers",
    version = PLUGIN_VERSION,
    url = "https://github.com/nanaimo2013/nans-surf-cs2"
};

// Current map name
char g_CurrentMap[PLATFORM_MAX_PATH];

// Recent records storage
enum struct RecentRecord {
    char SteamID[32];
    char Name[MAX_NAME_LENGTH];
    char Map[PLATFORM_MAX_PATH];
    float Time;
    int Rank;
    bool IsPB;
    int Timestamp;
}

ArrayList g_RecentRecords;

// Forwards
Handle g_hForward_OnRecordAnnounced;

public void OnPluginStart() {
    // Initialize recent records array
    g_RecentRecords = new ArrayList(sizeof(RecentRecord));
    
    // Create natives for external access
    // Combined data endpoints
    CreateNative("NansSurfDiscord_GetPlayerStats", Native_GetPlayerStats);
    CreateNative("NansSurfDiscord_GetTopPlayers", Native_GetTopPlayers);
    CreateNative("NansSurfDiscord_GetServerInfo", Native_GetServerInfo);
    CreateNative("NansSurfDiscord_GetMapInfo", Native_GetMapInfo);
    
    // Individual player data
    CreateNative("NansSurfDiscord_GetPlayerRank", Native_GetPlayerRank);
    CreateNative("NansSurfDiscord_GetPlayerBestTime", Native_GetPlayerBestTime);
    CreateNative("NansSurfDiscord_GetPlayerTotalRuns", Native_GetPlayerTotalRuns);
    CreateNative("NansSurfDiscord_GetPlayerName", Native_GetPlayerName);
    CreateNative("NansSurfDiscord_IsPlayerOnline", Native_IsPlayerOnline);
    
    // Individual map data
    CreateNative("NansSurfDiscord_GetMapRecord", Native_GetMapRecord);
    CreateNative("NansSurfDiscord_GetMapRecordHolder", Native_GetMapRecordHolder);
    CreateNative("NansSurfDiscord_GetMapCompletions", Native_GetMapCompletions);
    CreateNative("NansSurfDiscord_GetMapAverageTime", Native_GetMapAverageTime);
    
    // Server data
    CreateNative("NansSurfDiscord_GetOnlinePlayerCount", Native_GetOnlinePlayerCount);
    CreateNative("NansSurfDiscord_GetActivePlayerCount", Native_GetActivePlayerCount);
    CreateNative("NansSurfDiscord_GetTotalRankedPlayers", Native_GetTotalRankedPlayers);
    CreateNative("NansSurfDiscord_GetCurrentMap", Native_GetCurrentMap);
    
    // Leaderboard data
    CreateNative("NansSurfDiscord_GetTopTimes", Native_GetTopTimes);
    CreateNative("NansSurfDiscord_GetRecentRecords", Native_GetRecentRecords);
    CreateNative("NansSurfDiscord_GetPlayerPosition", Native_GetPlayerPosition);
    
    // Record announcements
    CreateNative("NansSurfDiscord_AnnounceRecord", Native_AnnounceRecord);
    
    // Utility functions
    CreateNative("NansSurfDiscord_FormatTime", Native_FormatTime);
    CreateNative("NansSurfDiscord_GetFormattedRank", Native_GetFormattedRank);
    
    // Create forwards
    g_hForward_OnRecordAnnounced = CreateGlobalForward("NansSurfDiscord_OnRecordAnnounced", 
        ET_Ignore, Param_Cell, Param_Float, Param_Cell, Param_Cell);
}

public void OnMapStart() {
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
}

// Helper functions
int FindClientBySteamId(const char[] steamId) {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            char tempSteamId[32];
            if (GetClientAuthId(i, AuthId_Steam2, tempSteamId, sizeof(tempSteamId)) && 
                strcmp(steamId, tempSteamId) == 0) {
                return i;
            }
        }
    }
    return -1;
}

void AddRecentRecord(int client, float time, int rank, bool isPB) {
    RecentRecord record;
    GetClientAuthId(client, AuthId_Steam2, record.SteamID, sizeof(RecentRecord::SteamID));
    GetClientName(client, record.Name, sizeof(RecentRecord::Name));
    strcopy(record.Map, sizeof(RecentRecord::Map), g_CurrentMap);
    record.Time = time;
    record.Rank = rank;
    record.IsPB = isPB;
    record.Timestamp = GetTime();
    
    // Add to front of array
    g_RecentRecords.ShiftUp(0);
    g_RecentRecords.SetArray(0, record);
    
    // Trim if too long
    if (g_RecentRecords.Length > MAX_RECENT_RECORDS) {
        g_RecentRecords.Resize(MAX_RECENT_RECORDS);
    }
}

// Combined data endpoints
public int Native_GetPlayerStats(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    
    int client = FindClientBySteamId(steamId);
    if (client == -1) {
        SetNativeString(2, "{\"error\":\"Player not found\"}", GetNativeCell(3));
        return false;
    }
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    int totalRuns = NansSurfStats_GetTotalRuns(client);
    float bestTime = NansSurfStats_GetBestTime(client);
    int rank = NansSurfStats_GetRank(client);
    
    char timeStr[32];
    FormatSeconds(bestTime, timeStr, sizeof(timeStr));
    
    char response[512];
    Format(response, sizeof(response), 
        "{\"name\":\"%s\",\"steamId\":\"%s\",\"totalRuns\":%d,\"bestTime\":\"%s\",\"rank\":%d,\"totalPlayers\":%d,\"online\":true}", 
        name, steamId, totalRuns, timeStr, rank, NansSurfStats_GetTotalRankedPlayers());
    
    SetNativeString(2, response, GetNativeCell(3));
    return true;
}

// Individual player data
public int Native_GetPlayerRank(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    
    int client = FindClientBySteamId(steamId);
    return (client != -1) ? NansSurfStats_GetRank(client) : 0;
}

public int Native_GetPlayerBestTime(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    
    int client = FindClientBySteamId(steamId);
    return (client != -1) ? view_as<int>(NansSurfStats_GetBestTime(client)) : -1;
}

public int Native_GetPlayerTotalRuns(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    
    int client = FindClientBySteamId(steamId);
    return (client != -1) ? NansSurfStats_GetTotalRuns(client) : 0;
}

public int Native_GetPlayerName(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    
    int client = FindClientBySteamId(steamId);
    if (client == -1) return false;
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    SetNativeString(2, name, GetNativeCell(3));
    return true;
}

public int Native_IsPlayerOnline(Handle plugin, int numParams) {
    char steamId[32];
    GetNativeString(1, steamId, sizeof(steamId));
    return FindClientBySteamId(steamId) != -1;
}

// Individual map data
public int Native_GetMapRecord(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    return view_as<int>(NansSurfStats_GetMapRecord(map));
}

public int Native_GetMapRecordHolder(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    
    char holder[MAX_NAME_LENGTH];
    bool success = NansSurfStats_GetMapRecordHolder(map, holder, sizeof(holder));
    if (success) {
        SetNativeString(2, holder, GetNativeCell(3));
    }
    return success;
}

public int Native_GetMapCompletions(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    return NansSurfStats_GetMapCompletions(map);
}

// Server data
public int Native_GetOnlinePlayerCount(Handle plugin, int numParams) {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) count++;
    }
    return count;
}

public int Native_GetActivePlayerCount(Handle plugin, int numParams) {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i) && NansSurfTimer_IsTimerRunning(i)) {
            count++;
        }
    }
    return count;
}

public int Native_GetTotalRankedPlayers(Handle plugin, int numParams) {
    return NansSurfStats_GetTotalRankedPlayers();
}

public int Native_GetCurrentMap(Handle plugin, int numParams) {
    SetNativeString(1, g_CurrentMap, GetNativeCell(2));
    return true;
}

public int Native_GetServerInfo(Handle plugin, int numParams) {
    int playerCount = Native_GetOnlinePlayerCount(plugin, 0);
    int activeCount = Native_GetActivePlayerCount(plugin, 0);
    int totalRanked = Native_GetTotalRankedPlayers(plugin, 0);
    
    char response[512];
    Format(response, sizeof(response), 
        "{\"players\":%d,\"maxPlayers\":%d,\"activePlayers\":%d,\"map\":\"%s\",\"totalRankedPlayers\":%d}", 
        playerCount, MaxClients, activeCount, g_CurrentMap, totalRanked);
    
    SetNativeString(1, response, GetNativeCell(2));
    return true;
}

public int Native_GetMapInfo(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    
    // Get map stats
    int completions = NansSurfStats_GetMapCompletions(map);
    float recordTime = NansSurfStats_GetMapRecord(map);
    float avgTime = view_as<float>(Native_GetMapAverageTime(plugin, 0));
    
    char recordHolder[MAX_NAME_LENGTH];
    NansSurfStats_GetMapRecordHolder(map, recordHolder, sizeof(recordHolder));
    
    char timeStr[32], avgTimeStr[32];
    FormatSeconds(recordTime, timeStr, sizeof(timeStr));
    FormatSeconds(avgTime, avgTimeStr, sizeof(avgTimeStr));
    
    char response[512];
    Format(response, sizeof(response), 
        "{\"name\":\"%s\",\"completions\":%d,\"recordTime\":\"%s\",\"recordHolder\":\"%s\",\"averageTime\":\"%s\"}", 
        map, completions, timeStr, recordHolder, avgTimeStr);
    
    SetNativeString(2, response, GetNativeCell(3));
    return true;
}

public int Native_GetMapAverageTime(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    
    // For now, return a placeholder value since we don't have average time tracking yet
    return view_as<int>(0.0);
}

public int Native_GetTopPlayers(Handle plugin, int numParams) {
    int limit = GetNativeCell(1);
    if (limit <= 0) limit = 10;
    if (limit > 100) limit = 100;
    
    // Build top players list
    char response[4096] = "{\"players\":[";
    int playersAdded = 0;
    
    for (int i = 1; i <= MaxClients && playersAdded < limit; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        
        char name[MAX_NAME_LENGTH], steamId[32];
        GetClientName(i, name, sizeof(name));
        GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId));
        
        float bestTime = NansSurfStats_GetBestTime(i);
        if (bestTime <= 0.0) continue;
        
        int rank = NansSurfStats_GetRank(i);
        int totalRuns = NansSurfStats_GetTotalRuns(i);
        
        char timeStr[32];
        FormatSeconds(bestTime, timeStr, sizeof(timeStr));
        
        if (playersAdded > 0) StrCat(response, sizeof(response), ",");
        Format(response, sizeof(response), 
            "%s{\"name\":\"%s\",\"steamId\":\"%s\",\"bestTime\":\"%s\",\"rank\":%d,\"totalRuns\":%d}", 
            response, name, steamId, timeStr, rank, totalRuns);
        playersAdded++;
    }
    
    StrCat(response, sizeof(response), "]}");
    SetNativeString(2, response, GetNativeCell(3));
    return true;
}

// Leaderboard data
public int Native_GetTopTimes(Handle plugin, int numParams) {
    char map[PLATFORM_MAX_PATH];
    GetNativeString(1, map, sizeof(map));
    int limit = GetNativeCell(2);
    if (limit <= 0) limit = 10;
    if (limit > 100) limit = 100;
    
    char response[4096] = "{\"times\":[";
    
    // Implementation needed: Get top times for specific map
    // This would require additional natives in NansSurfStats
    
    StrCat(response, sizeof(response), "]}");
    SetNativeString(3, response, GetNativeCell(4));
    return true;
}

public int Native_GetRecentRecords(Handle plugin, int numParams) {
    int limit = GetNativeCell(1);
    if (limit <= 0) limit = 10;
    if (limit > MAX_RECENT_RECORDS) limit = MAX_RECENT_RECORDS;
    
    char response[4096] = "{\"records\":[";
    
    for (int i = 0; i < g_RecentRecords.Length && i < limit; i++) {
        RecentRecord record;
        g_RecentRecords.GetArray(i, record);
        
        char timeStr[32];
        FormatSeconds(record.Time, timeStr, sizeof(timeStr));
        
        if (i > 0) StrCat(response, sizeof(response), ",");
        Format(response, sizeof(response), 
            "%s{\"name\":\"%s\",\"steamId\":\"%s\",\"map\":\"%s\",\"time\":\"%s\",\"rank\":%d,\"isPB\":%s,\"timestamp\":%d}", 
            response, record.Name, record.SteamID, record.Map, timeStr, record.Rank, 
            record.IsPB ? "true" : "false", record.Timestamp);
    }
    
    StrCat(response, sizeof(response), "]}");
    SetNativeString(2, response, GetNativeCell(3));
    return true;
}

public int Native_GetPlayerPosition(Handle plugin, int numParams) {
    char steamId[32], map[PLATFORM_MAX_PATH];
    GetNativeString(1, steamId, sizeof(steamId));
    GetNativeString(2, map, sizeof(map));
    
    int client = FindClientBySteamId(steamId);
    if (client == -1) return false;
    
    int position = NansSurfStats_GetRank(client);
    float time = NansSurfStats_GetBestTime(client);
    
    SetNativeCellRef(3, position);
    SetNativeCellRef(4, time);
    return true;
}

// Record announcements
public int Native_AnnounceRecord(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    float time = GetNativeCell(2);
    int rank = GetNativeCell(3);
    bool isPB = GetNativeCell(4);
    
    if (!IsValidClient(client)) return false;
    
    // Add to recent records
    AddRecentRecord(client, time, rank, isPB);
    
    // Forward the event
    Call_StartForward(g_hForward_OnRecordAnnounced);
    Call_PushCell(client);
    Call_PushFloat(time);
    Call_PushCell(rank);
    Call_PushCell(isPB);
    Call_Finish();
    
    return true;
}

// Utility functions
public int Native_FormatTime(Handle plugin, int numParams) {
    float time = GetNativeCell(1);
    char buffer[32];
    FormatSeconds(time, buffer, sizeof(buffer));
    SetNativeString(2, buffer, GetNativeCell(3));
    return true;
}

public int Native_GetFormattedRank(Handle plugin, int numParams) {
    int rank = GetNativeCell(1);
    char buffer[16];
    
    if (rank == 1) strcopy(buffer, sizeof(buffer), "1st");
    else if (rank == 2) strcopy(buffer, sizeof(buffer), "2nd");
    else if (rank == 3) strcopy(buffer, sizeof(buffer), "3rd");
    else Format(buffer, sizeof(buffer), "%dth", rank);
    
    SetNativeString(2, buffer, GetNativeCell(3));
    return true;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

void FormatSeconds(float time, char[] buffer, int maxlen) {
    if (time <= 0.0) {
        strcopy(buffer, maxlen, "N/A");
        return;
    }
    
    int minutes = RoundToFloor(time / 60.0);
    float seconds = time - float(minutes * 60);
    
    if (minutes > 0) {
        Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
    } else {
        Format(buffer, maxlen, "%.2f", seconds);
    }
} 