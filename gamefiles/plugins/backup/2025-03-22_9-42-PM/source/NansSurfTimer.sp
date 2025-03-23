#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <NansSurf>
#include <NansSurfStats>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = {
    name = "Nans Surf Timer",
    author = "Nanaimo_2013",
    description = "Timer system for CS2 Surf servers",
    version = PLUGIN_VERSION,
    url = "https://github.com/nanaimo2013/nans-surf-cs2"
};

// Timer states
enum struct PlayerTimer {
    float StartTime;
    float CurrentTime;
    bool IsRunning;
    int CurrentCheckpoint;
    ArrayList CheckpointTimes;
}

PlayerTimer g_PlayerTimers[MAXPLAYERS + 1];

// HUD settings
ConVar g_cvHudEnabled;
ConVar g_cvHudPosition;
ConVar g_cvHudColor;

// Forwards
Handle g_hForward_OnTimerStart;
Handle g_hForward_OnTimerStop;
Handle g_hForward_OnTimerReset;

public void OnPluginStart() {
    // Register commands
    RegConsoleCmd("sm_r", Command_Restart, "Restart current run");
    RegConsoleCmd("sm_restart", Command_Restart, "Restart current run");
    RegConsoleCmd("sm_cp", Command_Checkpoint, "Save checkpoint");
    RegConsoleCmd("sm_tp", Command_Teleport, "Teleport to checkpoint");
    RegConsoleCmd("sm_showtime", Command_ShowTime, "Show current time");

    // Create convars
    g_cvHudEnabled = CreateConVar("sm_timer_hud_enabled", "1", "Enable timer HUD");
    g_cvHudPosition = CreateConVar("sm_timer_hud_position", "0.05 0.05", "HUD position (x y)");
    g_cvHudColor = CreateConVar("sm_timer_hud_color", "255 255 255", "HUD color (r g b)");

    // Create natives
    CreateNative("NansSurfTimer_IsTimerRunning", Native_IsTimerRunning);
    CreateNative("NansSurfTimer_GetCurrentTime", Native_GetCurrentTime);
    CreateNative("NansSurfTimer_StopTimer", Native_StopTimer);
    CreateNative("NansSurfTimer_ResetTimer", Native_ResetTimer);

    // Create forwards
    g_hForward_OnTimerStart = CreateGlobalForward("NansSurfTimer_OnTimerStart", ET_Ignore, Param_Cell);
    g_hForward_OnTimerStop = CreateGlobalForward("NansSurfTimer_OnTimerStop", ET_Ignore, Param_Cell, Param_Float, Param_Cell);
    g_hForward_OnTimerReset = CreateGlobalForward("NansSurfTimer_OnTimerReset", ET_Ignore, Param_Cell);

    // Initialize player timers
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client) {
    g_PlayerTimers[client].CheckpointTimes = new ArrayList();
    ResetTimer(client);
}

public void OnClientDisconnect(int client) {
    delete g_PlayerTimers[client].CheckpointTimes;
}

public Action Command_Restart(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    ResetTimer(client);
    // Get spawn position from NansSurf
    float spawnPos[3], angles[3];
    if (NansSurf_GetSpawnPosition(spawnPos, angles)) {
        TeleportEntity(client, spawnPos, angles, NULL_VECTOR);
    }
    
    return Plugin_Handled;
}

public Action Command_Checkpoint(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    SaveCheckpoint(client);
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    TeleportToCheckpoint(client);
    return Plugin_Handled;
}

public Action Command_ShowTime(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (!g_PlayerTimers[client].IsRunning) {
        PrintToChat(client, "Timer is not running.");
        return Plugin_Handled;
    }
    
    char timeStr[32];
    FormatSeconds(g_PlayerTimers[client].CurrentTime, timeStr, sizeof(timeStr));
    PrintToChat(client, "Current time: %s", timeStr);
    
    return Plugin_Handled;
}

void ResetTimer(int client) {
    g_PlayerTimers[client].IsRunning = false;
    g_PlayerTimers[client].StartTime = 0.0;
    g_PlayerTimers[client].CurrentTime = 0.0;
    g_PlayerTimers[client].CurrentCheckpoint = 0;
    g_PlayerTimers[client].CheckpointTimes.Clear();

    // Forward the event
    Call_StartForward(g_hForward_OnTimerReset);
    Call_PushCell(client);
    Call_Finish();
}

void StartTimer(int client) {
    g_PlayerTimers[client].IsRunning = true;
    g_PlayerTimers[client].StartTime = GetGameTime();

    // Forward the event
    Call_StartForward(g_hForward_OnTimerStart);
    Call_PushCell(client);
    Call_Finish();
}

void StopTimer(int client) {
    if (!g_PlayerTimers[client].IsRunning) return;
    
    g_PlayerTimers[client].IsRunning = false;
    float finalTime = GetGameTime() - g_PlayerTimers[client].StartTime;
    
    // Get current best time
    float bestTime = view_as<float>(NansSurfStats_GetBestTime(client));
    bool isPB = bestTime < 0.0 || finalTime < bestTime;
    
    // Send time to stats system
    NansSurfStats_SubmitTime(client, finalTime);

    // Forward the event
    Call_StartForward(g_hForward_OnTimerStop);
    Call_PushCell(client);
    Call_PushFloat(finalTime);
    Call_PushCell(isPB);
    Call_Finish();
}

void SaveCheckpoint(int client) {
    if (!g_PlayerTimers[client].IsRunning) return;
    
    float checkpointTime = GetGameTime() - g_PlayerTimers[client].StartTime;
    g_PlayerTimers[client].CheckpointTimes.Push(checkpointTime);
    g_PlayerTimers[client].CurrentCheckpoint++;
}

void TeleportToCheckpoint(int client) {
    if (!IsValidClient(client)) return;
    
    float position[3], angles[3];
    if (NansSurf_GetSpawnPosition(position, angles)) {
        TeleportEntity(client, position, angles, NULL_VECTOR);
    }
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

// Forward from NansSurf when player enters start zone
public void NansSurf_OnPlayerEnterStartZone(int client) {
    StartTimer(client);
}

// Forward from NansSurf when player enters end zone
public void NansSurf_OnPlayerEnterEndZone(int client) {
    StopTimer(client);
}

// Native implementations
public int Native_IsTimerRunning(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return false;
    return g_PlayerTimers[client].IsRunning;
}

public int Native_GetCurrentTime(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client) || !g_PlayerTimers[client].IsRunning) return view_as<int>(-1.0);
    return view_as<int>(GetGameTime() - g_PlayerTimers[client].StartTime);
}

public int Native_StopTimer(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return false;
    StopTimer(client);
    return true;
}

public int Native_ResetTimer(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    if (!IsValidClient(client)) return false;
    ResetTimer(client);
    return true;
}

// Add HUD functionality
void UpdateHUD(int client) {
    if (!g_cvHudEnabled.BoolValue) return;
    
    if (!IsValidClient(client) || !g_PlayerTimers[client].IsRunning) return;
    
    char hudText[256];
    float currentTime = GetGameTime() - g_PlayerTimers[client].StartTime;
    
    char timeString[32];
    FormatSeconds(currentTime, timeString, sizeof(timeString));
    
    // Get HUD position from cvar
    char posStr[32];
    g_cvHudPosition.GetString(posStr, sizeof(posStr));
    
    // Parse position values
    char posValues[2][8];
    ExplodeString(posStr, ",", posValues, sizeof(posValues), sizeof(posValues[]));
    float x = StringToFloat(posValues[0]);
    float y = StringToFloat(posValues[1]);
    
    // Get HUD color from cvar
    char colorStr[32];
    g_cvHudColor.GetString(colorStr, sizeof(colorStr));
    
    // Parse color values
    char colorValues[3][4];
    ExplodeString(colorStr, ",", colorValues, sizeof(colorValues), sizeof(colorValues[]));
    int r = StringToInt(colorValues[0]);
    int g = StringToInt(colorValues[1]);
    int b = StringToInt(colorValues[2]);
    
    Format(hudText, sizeof(hudText), "Time: %s", timeString);
    
    // Show HUD text
    SetHudTextParams(x, y, 1.0, r, g, b, 255, 0, 0.0, 0.0, 0.0);
    ShowHudText(client, -1, hudText);
}

// Add the FormatSeconds function
void FormatSeconds(float time, char[] buffer, int maxlen) {
    int minutes = RoundToFloor(time / 60.0);
    float seconds = time - float(minutes * 60);
    
    if (minutes > 0) {
        Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
    } else {
        Format(buffer, maxlen, "%.2f", seconds);
    }
}

public void OnGameFrame() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) continue;
        
        if (g_PlayerTimers[i].IsRunning) {
            g_PlayerTimers[i].CurrentTime = GetGameTime() - g_PlayerTimers[i].StartTime;
            UpdateHUD(i);
        }
    }
} 