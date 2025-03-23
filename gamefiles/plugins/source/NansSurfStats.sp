#include <sourcemod>
#include <sdktools>
#include <NansSurf>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define MAX_RANKS 1000

public Plugin myinfo = {
    name = "Nans Surf Stats",
    author = "Nanaimo_2013",
    description = "Statistics tracking for CS2 Surf servers",
    version = PLUGIN_VERSION,
    url = "https://github.com/nanaimo2013/nans-surf-cs2"
};

// Player data structure
enum struct PlayerStats {
    char SteamID[32];
    char Name[MAX_NAME_LENGTH];
    int TotalRuns;
    float BestTime;
    int Rank;
    char LastSeen[64];
}

// Global variables
ArrayList g_PlayerStats;
StringMap g_MapRecords;
char g_StatsPath[PLATFORM_MAX_PATH];
char g_RecordsPath[PLATFORM_MAX_PATH];

// Forwards
Handle g_hForward_OnStatsLoaded;
Handle g_hForward_OnRunComplete;

public void OnPluginStart() {
    // Initialize data structures
    g_PlayerStats = new ArrayList(sizeof(PlayerStats));
    g_MapRecords = new StringMap();
    
    // Create natives
    CreateNative("NansSurfStats_GetTotalRuns", Native_GetTotalRuns);
    CreateNative("NansSurfStats_GetBestTime", Native_GetBestTime);
    CreateNative("NansSurfStats_GetRank", Native_GetRank);
    CreateNative("NansSurfStats_GetTotalRankedPlayers", Native_GetTotalRankedPlayers);
    CreateNative("NansSurfStats_SubmitTime", Native_SubmitTime);
    
    // Create forwards
    g_hForward_OnStatsLoaded = CreateGlobalForward("NansSurfStats_OnStatsLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
    g_hForward_OnRunComplete = CreateGlobalForward("NansSurfStats_OnRunComplete", ET_Ignore, Param_Cell, Param_Float, Param_Cell);
    
    // Build file paths
    BuildPath(Path_SM, g_StatsPath, sizeof(g_StatsPath), "data/surf/stats");
    BuildPath(Path_SM, g_RecordsPath, sizeof(g_RecordsPath), "data/surf/records");
    
    // Create directories if they don't exist
    if (!DirExists(g_StatsPath)) {
        CreateDirectory(g_StatsPath, 511);
    }
    if (!DirExists(g_RecordsPath)) {
        CreateDirectory(g_RecordsPath, 511);
    }
    
    // Load all stats
    LoadAllStats();
}

public void OnMapStart() {
    // Load map records
    char currentMap[PLATFORM_MAX_PATH];
    GetCurrentMap(currentMap, sizeof(currentMap));
    LoadMapRecords(currentMap);
}

public void OnClientConnected(int client) {
    if (!IsValidClient(client)) return;
    LoadPlayerStats(client);
}

public void OnClientDisconnect(int client) {
    if (!IsValidClient(client)) return;
    SavePlayerStats(client);
}

void LoadAllStats() {
    // Clear existing stats
    g_PlayerStats.Clear();
    g_MapRecords.Clear();
    
    // Open stats directory
    DirectoryListing dir = OpenDirectory(g_StatsPath);
    if (dir == null) return;
    
    // Read all stat files
    char filename[PLATFORM_MAX_PATH];
    FileType type;
    while (dir.GetNext(filename, sizeof(filename), type)) {
        if (type != FileType_File) continue;
        if (StrContains(filename, ".stats") == -1) continue;
        
        char filepath[PLATFORM_MAX_PATH];
        Format(filepath, sizeof(filepath), "%s/%s", g_StatsPath, filename);
        LoadPlayerStatsFile(filepath);
    }
    
    delete dir;
    
    // Sort and update ranks
    SortStats();
}

void LoadPlayerStatsFile(const char[] filePath) {
    File file = OpenFile(filePath, "r");
    if (file == null) {
        LogError("Failed to open player stats file: %s", filePath);
        return;
    }
    
    PlayerStats stats;
    char line[256];
    
    if (file.ReadLine(line, sizeof(line))) {
        TrimString(line);
        strcopy(stats.SteamID, sizeof(PlayerStats::SteamID), line);
        
        if (file.ReadLine(line, sizeof(line))) {
            TrimString(line);
            strcopy(stats.Name, sizeof(PlayerStats::Name), line);
            
            if (file.ReadLine(line, sizeof(line))) {
                TrimString(line);
                stats.TotalRuns = StringToInt(line);
                
                if (file.ReadLine(line, sizeof(line))) {
                    TrimString(line);
                    stats.BestTime = StringToFloat(line);
                    
                    if (file.ReadLine(line, sizeof(line))) {
                        TrimString(line);
                        strcopy(stats.LastSeen, sizeof(PlayerStats::LastSeen), line);
                        
                        g_PlayerStats.PushArray(stats);
                        SortStats();
                    }
                }
            }
        }
    }
    
    delete file;
}

void LoadPlayerStats(int client) {
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return;
    
    char filepath[PLATFORM_MAX_PATH];
    Format(filepath, sizeof(filepath), "%s/%s.stats", g_StatsPath, steamid[8]);
    
    PlayerStats stats;
    strcopy(stats.SteamID, sizeof(stats.SteamID), steamid);
    GetClientName(client, stats.Name, sizeof(stats.Name));
    stats.TotalRuns = 0;
    stats.BestTime = -1.0;
    FormatTime(stats.LastSeen, sizeof(stats.LastSeen), "%Y-%m-%d %H:%M:%S");
    
    if (FileExists(filepath)) {
        KeyValues kv = new KeyValues("PlayerStats");
        if (kv.ImportFromFile(filepath)) {
            stats.TotalRuns = kv.GetNum("total_runs", 0);
            stats.BestTime = kv.GetFloat("best_time", -1.0);
        }
        delete kv;
    }
    
    g_PlayerStats.PushArray(stats);
    SortStats();
    
    // Forward the event
    Call_StartForward(g_hForward_OnStatsLoaded);
    Call_PushCell(client);
    Call_PushCell(stats.TotalRuns);
    Call_PushFloat(stats.BestTime);
    Call_Finish();
}

void SavePlayerStats(int client) {
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return;
    
    char filepath[PLATFORM_MAX_PATH];
    Format(filepath, sizeof(filepath), "%s/%s.stats", g_StatsPath, steamid[8]);
    
    int index = FindPlayerStats(steamid);
    if (index == -1) return;
    
    PlayerStats stats;
    g_PlayerStats.GetArray(index, stats);
    FormatTime(stats.LastSeen, sizeof(stats.LastSeen), "%Y-%m-%d %H:%M:%S");
    
    KeyValues kv = new KeyValues("PlayerStats");
    kv.SetString("steamid", stats.SteamID);
    kv.SetString("name", stats.Name);
    kv.SetNum("total_runs", stats.TotalRuns);
    kv.SetFloat("best_time", stats.BestTime);
    kv.SetString("last_seen", stats.LastSeen);
    kv.ExportToFile(filepath);
    delete kv;
}

void LoadMapRecords(const char[] map) {
    char filepath[PLATFORM_MAX_PATH];
    Format(filepath, sizeof(filepath), "%s/%s.records", g_RecordsPath, map);
    
    if (!FileExists(filepath)) return;
    
    KeyValues kv = new KeyValues("MapRecords");
    if (!kv.ImportFromFile(filepath)) {
        delete kv;
        return;
    }
    
    if (kv.GotoFirstSubKey(false)) {
        do {
            char steamid[32];
            kv.GetSectionName(steamid, sizeof(steamid));
            float time = kv.GetFloat(NULL_STRING, -1.0);
            if (time > 0.0) {
                char timeStr[32];
                FloatToString(time, timeStr, sizeof(timeStr));
                g_MapRecords.SetString(steamid, timeStr);
            }
        } while (kv.GotoNextKey(false));
    }
    
    delete kv;
}

void SaveMapRecord(const char[] map, const char[] steamid, float time) {
    char filepath[PLATFORM_MAX_PATH];
    Format(filepath, sizeof(filepath), "%s/%s.records", g_RecordsPath, map);
    
    KeyValues kv = new KeyValues("MapRecords");
    kv.ImportFromFile(filepath);
    
    kv.JumpToKey(steamid, true);
    kv.SetFloat(NULL_STRING, time);
    
    kv.ExportToFile(filepath);
    delete kv;
    
    // Update in-memory record
    char timeStr[32];
    FloatToString(time, timeStr, sizeof(timeStr));
    g_MapRecords.SetString(steamid, timeStr);
}

int FindPlayerStats(const char[] steamid) {
    PlayerStats stats;
    for (int i = 0; i < g_PlayerStats.Length; i++) {
        g_PlayerStats.GetArray(i, stats);
        if (StrEqual(stats.SteamID, steamid)) {
            return i;
        }
    }
    return -1;
}

void SortStats() {
    // Sort by best time
    g_PlayerStats.SortCustom(SortByTime);
    
    // Update ranks
    PlayerStats stats;
    for (int i = 0; i < g_PlayerStats.Length; i++) {
        g_PlayerStats.GetArray(i, stats);
        stats.Rank = i + 1;
        g_PlayerStats.SetArray(i, stats);
    }
}

public int SortByTime(int index1, int index2, Handle array, Handle hndl) {
    ArrayList list = view_as<ArrayList>(array);
    PlayerStats stats1, stats2;
    
    list.GetArray(index1, stats1);
    list.GetArray(index2, stats2);
    
    if (stats1.BestTime < 0.0 && stats2.BestTime < 0.0) return 0;
    if (stats1.BestTime < 0.0) return 1;
    if (stats2.BestTime < 0.0) return -1;
    
    if (stats1.BestTime < stats2.BestTime) return -1;
    if (stats1.BestTime > stats2.BestTime) return 1;
    return 0;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

// Native implementations
public int Native_GetTotalRuns(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return -1;
    
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return -1;
    
    int index = FindPlayerStats(steamid);
    if (index == -1) return 0;
    
    PlayerStats stats;
    g_PlayerStats.GetArray(index, stats);
    return stats.TotalRuns;
}

public int Native_GetBestTime(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return view_as<int>(-1.0);
    
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return view_as<int>(-1.0);
    
    int index = FindPlayerStats(steamid);
    if (index == -1) return view_as<int>(-1.0);
    
    PlayerStats stats;
    g_PlayerStats.GetArray(index, stats);
    return view_as<int>(stats.BestTime);
}

public int Native_GetRank(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return 0;
    
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return 0;
    
    int index = FindPlayerStats(steamid);
    if (index == -1) return 0;
    
    PlayerStats stats;
    g_PlayerStats.GetArray(index, stats);
    return stats.Rank;
}

public int Native_GetTotalRankedPlayers(Handle plugin, int numParams) {
    return g_PlayerStats.Length;
}

public int Native_SubmitTime(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    float time = GetNativeCell(2);
    
    if (!IsValidClient(client)) return false;
    
    char steamid[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return false;
    
    int index = FindPlayerStats(steamid);
    if (index == -1) return false;
    
    PlayerStats stats;
    g_PlayerStats.GetArray(index, stats);
    
    bool isPB = stats.BestTime < 0.0 || time < stats.BestTime;
    if (isPB) {
        stats.BestTime = time;
        char currentMap[PLATFORM_MAX_PATH];
        GetCurrentMap(currentMap, sizeof(currentMap));
        SaveMapRecord(currentMap, steamid, time);
    }
    
    stats.TotalRuns++;
    g_PlayerStats.SetArray(index, stats);
    SavePlayerStats(client);
    UpdatePlayerRanks();
    
    // Forward the event
    Call_StartForward(g_hForward_OnRunComplete);
    Call_PushCell(client);
    Call_PushFloat(time);
    Call_PushCell(isPB);
    Call_Finish();
    
    return true;
}

// Add this function to update ranks
void UpdatePlayerRanks() {
    SortStats();
    
    for (int i = 0; i < g_PlayerStats.Length; i++) {
        PlayerStats stats;
        g_PlayerStats.GetArray(i, stats);
        stats.Rank = i + 1;
        g_PlayerStats.SetArray(i, stats);
    }
}