#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.0"
#define MAX_ZONES 64
#define MAX_STYLES 8

// Database connection handle
Database g_Database = null;

// Player timer data structure
enum struct PlayerTimer {
    int StartTime;
    int CurrentZone;
    float BestTime;
    float CurrentTime;
    bool IsRunning;
    int Checkpoints[MAX_ZONES];
}

// Zone types
enum ZoneType {
    ZONE_START = 0,
    ZONE_END,
    ZONE_CHECKPOINT,
    ZONE_STAGE
}

// Surf styles
enum SurfStyle {
    STYLE_NORMAL = 0,
    STYLE_SIDEWAYS,
    STYLE_BACKWARDS,
    STYLE_HALF_SIDEWAYS,
    STYLE_AUTO_BHOP,
    STYLE_SCROLL
}

// Global variables
PlayerTimer g_PlayerTimers[MAXPLAYERS + 1];
ArrayList g_MapZones;
int g_TotalZones = 0;
char g_sCurrentMap[128];

public Plugin myinfo = {
    name = "Nans Surf Timer",
    author = "Nanaimo_2013",
    description = "Advanced Surf Timer for CS2",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() {
    // Create ConVars
    CreateConVar("sm_surftimer_version", PLUGIN_VERSION, "Nans Surf Timer Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    // Register commands
    RegConsoleCmd("sm_timer", Command_Timer, "Show current timer status");
    RegConsoleCmd("sm_checkpoint", Command_Checkpoint, "Save a checkpoint");
    RegConsoleCmd("sm_teleport", Command_Teleport, "Teleport to last checkpoint");
    RegConsoleCmd("sm_restart", Command_Restart, "Restart your run");
    RegConsoleCmd("sm_top", Command_TopTimes, "Show top times");
    
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_RoundStart);
    
    // Initialize database connection
    ConnectToDatabase();
}

void ConnectToDatabase() {
    char error[256];
    g_Database = SQL_Connect("surftimer", true, error, sizeof(error));
    
    if (g_Database == null) {
        LogError("Failed to connect to database: %s", error);
        return;
    }
    
    // Create necessary tables
    char query[1024];
    Format(query, sizeof(query), 
        "CREATE TABLE IF NOT EXISTS `surf_times` (" ...
        "`steamid` VARCHAR(32) NOT NULL, " ...
        "`map` VARCHAR(128) NOT NULL, " ...
        "`style` INT NOT NULL, " ...
        "`time` FLOAT NOT NULL, " ...
        "`timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " ...
        "PRIMARY KEY (`steamid`, `map`, `style`)" ...
        ")");
    
    SQL_FastQuery(g_Database, query);
}

public void OnMapStart() {
    // Get current map name
    GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));

    // Load map zones
    LoadMapZones();
    
    // Reset all player timers
    for (int i = 1; i <= MaxClients; i++) {
        ResetPlayerTimer(i);
    }
}

void LoadMapZones() {
    // Load zones from database or configuration file
    g_MapZones = new ArrayList(sizeof(ZoneType));
    
    // Placeholder for zone loading logic
    // This would typically read from a database or config file
}

void ResetPlayerTimer(int client) {
    g_PlayerTimers[client].StartTime = 0;
    g_PlayerTimers[client].CurrentZone = 0;
    g_PlayerTimers[client].BestTime = 0.0;
    g_PlayerTimers[client].CurrentTime = 0.0;
    g_PlayerTimers[client].IsRunning = false;
    
    for (int i = 0; i < MAX_ZONES; i++) {
        g_PlayerTimers[client].Checkpoints[i] = 0;
    }
}

public Action Command_Timer(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    float currentTime = g_PlayerTimers[client].CurrentTime;
    int currentZone = g_PlayerTimers[client].CurrentZone;
    
    PrintToChat(client, "\x04[Surf Timer]\x01 Current Time: %.2f | Current Zone: %d", currentTime, currentZone);
    
    return Plugin_Handled;
}

public Action Command_Checkpoint(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    // Save current position as checkpoint
    float origin[3];
    GetClientAbsOrigin(client, origin);
    
    int currentZone = g_PlayerTimers[client].CurrentZone;
    g_PlayerTimers[client].Checkpoints[currentZone] = GetTime();
    
    PrintToChat(client, "\x04[Surf Timer]\x01 Checkpoint saved at zone %d", currentZone);
    
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    int currentZone = g_PlayerTimers[client].CurrentZone;
    int checkpointTime = g_PlayerTimers[client].Checkpoints[currentZone];
    
    if (checkpointTime > 0) {
        // Teleport logic would go here
        PrintToChat(client, "\x04[Surf Timer]\x01 Teleported to checkpoint");
    } else {
        PrintToChat(client, "\x04[Surf Timer]\x01 No checkpoint available");
    }
    
    return Plugin_Handled;
}

public Action Command_Restart(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    ResetPlayerTimer(client);
    PrintToChat(client, "\x04[Surf Timer]\x01 Run restarted");
    
    return Plugin_Handled;
}

public Action Command_TopTimes(int client, int args) {
    if (!IsValidClient(client) || g_Database == null) return Plugin_Handled;
    
    // Fetch top times from database
    char query[512];
    Format(query, sizeof(query), 
        "SELECT steamid, time, style FROM surf_times " ...
        "WHERE map = '%s' ORDER BY time ASC LIMIT 10", 
        g_sCurrentMap);
    
    SQL_TQuery(g_Database, TopTimesCallback, query, GetClientUserId(client));
    
    return Plugin_Handled;
}

public void TopTimesCallback(Handle owner, Handle hndl, const char[] error, any data) {
    int client = GetClientOfUserId(data);
    
    if (!IsValidClient(client)) return;
    
    if (hndl == INVALID_HANDLE) {
        LogError("Top Times Query Error: %s", error);
        return;
    }
    
    PrintToChat(client, "\x04[Surf Timer]\x01 Top Times:");
    
    int rank = 1;
    while (SQL_FetchRow(hndl)) {
        char steamid[32];
        float time;
        int style;
        
        SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
        time = SQL_FetchFloat(hndl, 1);
        style = SQL_FetchInt(hndl, 2);
        
        PrintToChat(client, "#%d: %s - %.2f (Style: %d)", rank++, steamid, time, style);
    }
}

public void OnClientPutInServer(int client) {
    ResetPlayerTimer(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client)) {
        ResetPlayerTimer(client);
    }
    
    return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    // Reset all player timers at round start
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            ResetPlayerTimer(i);
        }
    }
    
    return Plugin_Continue;
}

// Utility Functions
bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
}

// Zone Detection and Timer Logic
public void OnGameFrame() {
    for (int client = 1; client <= MaxClients; client++) {
        if (!IsValidClient(client)) continue;
        
        // Check player's current zone
        int currentZone = GetPlayerZone(client);
        
        if (currentZone != g_PlayerTimers[client].CurrentZone) {
            HandleZoneTransition(client, g_PlayerTimers[client].CurrentZone, currentZone);
        }
        
        // Update timer if running
        if (g_PlayerTimers[client].IsRunning) {
            g_PlayerTimers[client].CurrentTime += GetTickInterval();
        }
    }
}

int GetPlayerZone(int client) {
    // Placeholder for zone detection logic
    // Would typically use a zone system that checks player position against predefined zones
    return 0;
}

void HandleZoneTransition(int client, int oldZone, int newZone) {
    // Handle different zone transitions
    switch (newZone) {
        case ZONE_START: {
            // Reset timer when entering start zone
            ResetPlayerTimer(client);
            g_PlayerTimers[client].IsRunning = true;
        }
        case ZONE_END: {
            // Complete run, save time
            CompleteRun(client);
        }
        case ZONE_CHECKPOINT: {
            // Save checkpoint
            g_PlayerTimers[client].Checkpoints[newZone] = GetTime();
        }
    }
    
    g_PlayerTimers[client].CurrentZone = newZone;
}

void CompleteRun(int client) {
    float runTime = g_PlayerTimers[client].CurrentTime;
    
    // Check if this is a personal best
    if (runTime < g_PlayerTimers[client].BestTime || g_PlayerTimers[client].BestTime == 0.0) {
        g_PlayerTimers[client].BestTime = runTime;
        
        // Save to database
        SaveRunToDatabase(client, runTime);
        
        PrintToChat(client, "\x04[Surf Timer]\x01 New Personal Best: %.2f", runTime);
    }
    
    // Stop the timer
    g_PlayerTimers[client].IsRunning = false;
}

void SaveRunToDatabase(int client, float time) {
    if (g_Database == null) return;
    
    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    
    char query[512];
    Format(query, sizeof(query), 
        "INSERT INTO surf_times (steamid, map, style, time) " ...
        "VALUES ('%s', '%s', %d, %f) " ...
        "ON DUPLICATE KEY UPDATE time = LEAST(time, %f)",
        steamid, g_sCurrentMap, 0, time, time);
    
    SQL_TQuery(g_Database, SaveRunCallback, query);
}

public void SaveRunCallback(Handle owner, Handle hndl, const char[] error, any data) {
    if (hndl == INVALID_HANDLE) {
        LogError("Save Run Error: %s", error);
    }
} 