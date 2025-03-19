#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
    name = "Nans Surf Timer",
    author = "Nans",
    description = "Timer system for surf maps",
    version = "1.0.0",
    url = ""
};

// Zone Types
enum struct ZoneType
{
    int type;
    float points[8][3];
    int entity;
    bool active;
}

// Zone Definitions
#define ZONE_START 0
#define ZONE_END 1
#define ZONE_CHECKPOINT 2
#define ZONE_BONUS_START 3
#define ZONE_BONUS_END 4

// Global Variables
ArrayList g_MapZones;
bool g_bTimerRunning[MAXPLAYERS + 1];
float g_fStartTime[MAXPLAYERS + 1];
float g_fCurrentTime[MAXPLAYERS + 1];
int g_iCurrentCheckpoint[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // Initialize arrays
    g_MapZones = new ArrayList(sizeof(ZoneType));
    
    // Register commands
    RegConsoleCmd("sm_timer", Command_Timer, "Timer commands");
    RegConsoleCmd("sm_checkpoint", Command_Checkpoint, "Show checkpoint menu");
    RegAdminCmd("sm_zone", Command_Zone, ADMFLAG_RCON, "Zone management commands");
    
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    
    // Load translations
    LoadTranslations("common.phrases");
}

public void OnMapStart()
{
    // Clear existing zones
    g_MapZones.Clear();
    
    // Load zones from config
    LoadZones();
    
    // Create timer for checking zones
    CreateTimer(0.1, Timer_CheckZones, _, TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
    ResetTimer(client);
}

public void OnClientDisconnect(int client)
{
    ResetTimer(client);
}

public Action Command_Timer(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    ShowTimerMenu(client);
    return Plugin_Handled;
}

public Action Command_Checkpoint(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    ShowCheckpointMenu(client);
    return Plugin_Handled;
}

public Action Command_Zone(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    ShowZoneMenu(client);
    return Plugin_Handled;
}

void ShowTimerMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Timer);
    menu.SetTitle("Timer Menu");
    
    menu.AddItem("start", "Start Timer");
    menu.AddItem("stop", "Stop Timer");
    menu.AddItem("restart", "Restart Timer");
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Timer(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "start"))
            {
                StartTimer(param1);
            }
            else if (StrEqual(info, "stop"))
            {
                StopTimer(param1);
            }
            else if (StrEqual(info, "restart"))
            {
                RestartTimer(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void ShowCheckpointMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Checkpoint);
    menu.SetTitle("Checkpoint Menu");
    
    char buffer[64];
    for (int i = 0; i < g_iCurrentCheckpoint[client]; i++)
    {
        Format(buffer, sizeof(buffer), "Checkpoint %d", i + 1);
        menu.AddItem("", buffer, ITEMDRAW_DISABLED);
    }
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Checkpoint(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void ShowZoneMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Zone);
    menu.SetTitle("Zone Menu");
    
    menu.AddItem("start", "Add Start Zone");
    menu.AddItem("end", "Add End Zone");
    menu.AddItem("checkpoint", "Add Checkpoint");
    menu.AddItem("bonus_start", "Add Bonus Start");
    menu.AddItem("bonus_end", "Add Bonus End");
    menu.AddItem("delete", "Delete Zone");
    
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Zone(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            if (StrEqual(info, "start"))
            {
                CreateZone(param1, ZONE_START);
            }
            else if (StrEqual(info, "end"))
            {
                CreateZone(param1, ZONE_END);
            }
            else if (StrEqual(info, "checkpoint"))
            {
                CreateZone(param1, ZONE_CHECKPOINT);
            }
            else if (StrEqual(info, "bonus_start"))
            {
                CreateZone(param1, ZONE_BONUS_START);
            }
            else if (StrEqual(info, "bonus_end"))
            {
                CreateZone(param1, ZONE_BONUS_END);
            }
            else if (StrEqual(info, "delete"))
            {
                ShowDeleteZoneMenu(param1);
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

void CreateZone(int client, int type)
{
    ZoneType zone;
    zone.type = type;
    zone.active = true;
    
    // Get player position for initial zone point
    float pos[3];
    GetClientAbsOrigin(client, pos);
    
    // Set initial points (create a cube around player position)
    for (int i = 0; i < 8; i++)
    {
        zone.points[i] = pos;
        zone.points[i][0] += (i & 1) ? 50.0 : -50.0;
        zone.points[i][1] += (i & 2) ? 50.0 : -50.0;
        zone.points[i][2] += (i & 4) ? 100.0 : 0.0;
    }
    
    // Create zone entity
    zone.entity = CreateZoneEntity(zone);
    
    // Add to zones array
    g_MapZones.PushArray(zone);
    
    // Save zones to config
    SaveZones();
}

int CreateZoneEntity(ZoneType zone)
{
    int entity = CreateEntityByName("trigger_multiple");
    if (entity == -1)
        return -1;
    
    DispatchKeyValue(entity, "spawnflags", "1");
    DispatchSpawn(entity);
    
    // Set entity position and size
    float mins[3], maxs[3];
    GetZoneMinsMaxs(zone, mins, maxs);
    
    float origin[3];
    for (int i = 0; i < 3; i++)
        origin[i] = (mins[i] + maxs[i]) / 2.0;
    
    TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
    
    // Set trigger size
    float size[3];
    for (int i = 0; i < 3; i++)
        size[i] = (maxs[i] - mins[i]) / 2.0;
    
    SetEntPropVector(entity, Prop_Send, "m_vecMins", size);
    SetEntPropVector(entity, Prop_Send, "m_vecMaxs", size);
    
    return entity;
}

void GetZoneMinsMaxs(ZoneType zone, float mins[3], float maxs[3])
{
    // Initialize with first point
    mins = zone.points[0];
    maxs = zone.points[0];
    
    // Find min and max values
    for (int i = 1; i < 8; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            if (zone.points[i][j] < mins[j])
                mins[j] = zone.points[i][j];
            if (zone.points[i][j] > maxs[j])
                maxs[j] = zone.points[i][j];
        }
    }
}

void LoadZones()
{
    // Implementation for loading zones from config file
    // This would read from a config file and populate g_MapZones
}

void SaveZones()
{
    // Implementation for saving zones to config file
    // This would write the current g_MapZones to a config file
}

public Action Timer_CheckZones(Handle timer)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            CheckPlayerZone(client);
        }
    }
    return Plugin_Continue;
}

void CheckPlayerZone(int client)
{
    float pos[3];
    GetClientAbsOrigin(client, pos);
    
    for (int i = 0; i < g_MapZones.Length; i++)
    {
        ZoneType zone;
        g_MapZones.GetArray(i, zone);
        
        if (!zone.active)
            continue;
        
        if (IsPointInZone(pos, zone))
        {
            HandleZoneEnter(client, zone);
        }
    }
}

bool IsPointInZone(float point[3], ZoneType zone)
{
    float mins[3], maxs[3];
    GetZoneMinsMaxs(zone, mins, maxs);
    
    return (point[0] >= mins[0] && point[0] <= maxs[0] &&
            point[1] >= mins[1] && point[1] <= maxs[1] &&
            point[2] >= mins[2] && point[2] <= maxs[2]);
}

void HandleZoneEnter(int client, ZoneType zone)
{
    switch (zone.type)
    {
        case ZONE_START:
        {
            StartTimer(client);
        }
        case ZONE_END:
        {
            FinishTimer(client);
        }
        case ZONE_CHECKPOINT:
        {
            HandleCheckpoint(client);
        }
        case ZONE_BONUS_START:
        {
            StartBonusTimer(client);
        }
        case ZONE_BONUS_END:
        {
            FinishBonusTimer(client);
        }
    }
}

void StartTimer(int client)
{
    g_bTimerRunning[client] = true;
    g_fStartTime[client] = GetGameTime();
    g_iCurrentCheckpoint[client] = 0;
    PrintToChat(client, " \x04[Timer]\x01 Timer started!");
}

void StopTimer(int client)
{
    g_bTimerRunning[client] = false;
    PrintToChat(client, " \x04[Timer]\x01 Timer stopped!");
}

void RestartTimer(int client)
{
    StartTimer(client);
}

void FinishTimer(int client)
{
    if (!g_bTimerRunning[client])
        return;
    
    float time = GetGameTime() - g_fStartTime[client];
    g_fCurrentTime[client] = time;
    g_bTimerRunning[client] = false;
    
    char timeStr[32];
    FormatTime(time, timeStr, sizeof(timeStr));
    PrintToChat(client, " \x04[Timer]\x01 Finished in %s!", timeStr);
}

void HandleCheckpoint(int client)
{
    if (!g_bTimerRunning[client])
        return;
    
    g_iCurrentCheckpoint[client]++;
    float time = GetGameTime() - g_fStartTime[client];
    
    char timeStr[32];
    FormatTime(time, timeStr, sizeof(timeStr));
    PrintToChat(client, " \x04[Timer]\x01 Checkpoint %d: %s", g_iCurrentCheckpoint[client], timeStr);
}

void StartBonusTimer(int client)
{
    StartTimer(client); // For now, treat bonus timer the same as regular timer
}

void FinishBonusTimer(int client)
{
    FinishTimer(client); // For now, treat bonus timer the same as regular timer
}

void ResetTimer(int client)
{
    g_bTimerRunning[client] = false;
    g_fStartTime[client] = 0.0;
    g_fCurrentTime[client] = 0.0;
    g_iCurrentCheckpoint[client] = 0;
}

void FormatTime(float time, char[] buffer, int maxlen)
{
    int minutes = RoundToFloor(time / 60.0);
    float seconds = time - float(minutes * 60);
    Format(buffer, maxlen, "%d:%05.2f", minutes, seconds);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        ResetTimer(client);
    }
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        StopTimer(client);
    }
    return Plugin_Continue;
} 