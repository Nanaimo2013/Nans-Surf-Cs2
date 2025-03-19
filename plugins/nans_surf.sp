#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <clientprefs>
#include <multicolors>
#include <mapchooser>
#include <timer>
#include <mysql>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Nans Surf Server"
#define PLUGIN_AUTHOR "Nanaimo_2013"
#define PLUGIN_DESCRIPTION "Comprehensive Surf Server Plugin for CS2"
#define PLUGIN_VERSION "2.1.0"
#define MAX_MAP_LENGTH 128
#define MAX_STYLE_NAME 32
#define MAX_RANKS 100
#define MYSQL_TABLE_PREFIX "porter_surf"

// Plugin information
public Plugin myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "https://github.com/Nanaimo2013/Nans-Surf-Cs2"
};

// Database handle
Handle g_hDatabase = null;

// ConVars
ConVar g_cvServerName;
ConVar g_cvSurfTimerEnabled;
ConVar g_cvRankingSystem;
ConVar g_cvMapVoteEnabled;
ConVar g_cvSurfSpeed;
ConVar g_cvSurfGravity;
ConVar g_cvSurfAcceleration;
ConVar g_cvSurfMaxSpeed;
ConVar g_cvSurfMinSpeed;
ConVar g_cvSurfAirAcceleration;
ConVar g_cvSurfWaterAcceleration;
ConVar g_cvSurfJumpPower;
ConVar g_cvSurfStrafeMultiplier;
ConVar g_cvSurfEnableOverlay;
ConVar g_cvSurfEnableLeaderboard;
ConVar g_cvSurfEnableCheckpoints;
ConVar g_cvSurfEnableTeleports;
ConVar g_cvSurfEnableRanks;
ConVar g_cvSurfPointsPerCompletion;
ConVar g_cvSurfBonusPoints;
ConVar g_cvSurfMapVoteTime;
ConVar g_cvSurfRTVRequiredPercentage;

// Player variables
float g_fPlayerSpeed[MAXPLAYERS + 1];
float g_fPlayerStartTime[MAXPLAYERS + 1];
float g_fPlayerBestTime[MAXPLAYERS + 1];
float g_fPlayerCheckpointTime[MAXPLAYERS + 1];
int g_iPlayerRank[MAXPLAYERS + 1];
int g_iPlayerPoints[MAXPLAYERS + 1];
int g_iPlayerCompletions[MAXPLAYERS + 1];
bool g_bIsSurfing[MAXPLAYERS + 1];
bool g_bHasCheckpoint[MAXPLAYERS + 1];
float g_fCheckpointPos[MAXPLAYERS + 1][3];
float g_fCheckpointAng[MAXPLAYERS + 1][3];
bool g_bInStartZone[MAXPLAYERS + 1];
bool g_bInEndZone[MAXPLAYERS + 1];
bool g_bTimerRunning[MAXPLAYERS + 1];
bool g_bSurfTimerActive[MAXPLAYERS + 1];

// Map variables
char g_sCurrentMap[MAX_MAP_LENGTH];
float g_fMapStartPos[3];
float g_fMapEndPos[3];
float g_fMapBestTime;
char g_sMapBestPlayer[MAX_NAME_LENGTH];
int g_iMapCompletions;
ArrayList g_hMapList;
ArrayList g_hMapCycle;

// RTV variables
bool g_bRTVEnabled;
int g_iRTVVotes;
int g_iRTVNeeded;
bool g_bHasVoted[MAXPLAYERS + 1];

// Style definitions
enum SurfStyle {
    Style_Normal = 0,
    Style_NoStrafe,
    Style_NoAccel,
    Style_NoBoost,
    Style_NoJump,
    Style_NoSpeed,
    Style_Backwards,
    Style_LowGravity,
    Style_HighGravity,
    Style_AutoHop,
    Style_NoAutoHop,
    Style_Expert
}

// Player preferences
int g_iPlayerStyle[MAXPLAYERS + 1];
bool g_bPlayerOverlay[MAXPLAYERS + 1];
float g_fPlayerSpeedMultiplier[MAXPLAYERS + 1];
bool g_bPlayerHideOtherPlayers[MAXPLAYERS + 1];
bool g_bPlayerAutoRestart[MAXPLAYERS + 1];

// Cookie handles
Handle g_hSpeedCookie;
Handle g_hStyleCookie;
Handle g_hOverlayCookie;
Handle g_hHidePlayersCookie;
Handle g_hAutoRestartCookie;

public void OnPluginStart()
{
    // Create ConVars
    CreateConVars();
    
    // Initialize database
    InitializeDatabase();
    
    // Create cookies
    CreateCookies();
    
    // Register commands
    RegisterCommands();
    
    // Hook events
    HookEvents();
    
    // Initialize map list
    InitializeMapList();
    
    // Load translations
    LoadTranslations("common.phrases");
    LoadTranslations("porter_surf.phrases");
    LoadTranslations("nans_surf.phrases");
}

void CreateConVars()
{
    // Server Settings
    g_cvServerName = CreateConVar("sm_surf_server_name", "Nans Surf Server", "Server Name");
    
    // Surf Timer Settings
    g_cvSurfTimerEnabled = CreateConVar("sm_surf_timer_enabled", "1", "Enable Surf Timer", FCVAR_NOTIFY);
    g_cvRankingSystem = CreateConVar("sm_surf_ranking_enabled", "1", "Enable Ranking System", FCVAR_NOTIFY);
    g_cvMapVoteEnabled = CreateConVar("sm_surf_mapvote_enabled", "1", "Enable Map Voting", FCVAR_NOTIFY);
    
    // Surf Timer Settings
    g_cvSurfSpeed = CreateConVar("surf_speed", "1.0", "Base surf speed multiplier", FCVAR_NOTIFY);
    g_cvSurfGravity = CreateConVar("surf_gravity", "800.0", "Surf gravity", FCVAR_NOTIFY);
    g_cvSurfAcceleration = CreateConVar("surf_acceleration", "1.0", "Surf acceleration multiplier", FCVAR_NOTIFY);
    g_cvSurfMaxSpeed = CreateConVar("surf_max_speed", "3500.0", "Maximum allowed speed", FCVAR_NOTIFY);
    g_cvSurfMinSpeed = CreateConVar("surf_min_speed", "100.0", "Minimum required speed", FCVAR_NOTIFY);
    g_cvSurfAirAcceleration = CreateConVar("surf_air_acceleration", "1.0", "Air acceleration multiplier", FCVAR_NOTIFY);
    g_cvSurfWaterAcceleration = CreateConVar("surf_water_acceleration", "1.0", "Water acceleration multiplier", FCVAR_NOTIFY);
    g_cvSurfJumpPower = CreateConVar("surf_jump_power", "1.0", "Jump power multiplier", FCVAR_NOTIFY);
    g_cvSurfStrafeMultiplier = CreateConVar("surf_strafe_multiplier", "1.0", "Strafe power multiplier", FCVAR_NOTIFY);
    g_cvSurfEnableOverlay = CreateConVar("surf_enable_overlay", "1", "Enable speed overlay", FCVAR_NOTIFY);
    g_cvSurfEnableLeaderboard = CreateConVar("surf_enable_leaderboard", "1", "Enable leaderboard system", FCVAR_NOTIFY);
    g_cvSurfEnableCheckpoints = CreateConVar("surf_enable_checkpoints", "1", "Enable checkpoint system", FCVAR_NOTIFY);
    g_cvSurfEnableTeleports = CreateConVar("surf_enable_teleports", "1", "Enable teleport system", FCVAR_NOTIFY);
    g_cvSurfEnableRanks = CreateConVar("surf_enable_ranks", "1", "Enable ranking system", FCVAR_NOTIFY);
    g_cvSurfPointsPerCompletion = CreateConVar("surf_points_completion", "100", "Points awarded for map completion", FCVAR_NOTIFY);
    g_cvSurfBonusPoints = CreateConVar("surf_points_bonus", "50", "Bonus points for beating personal best", FCVAR_NOTIFY);
    g_cvSurfMapVoteTime = CreateConVar("surf_mapvote_time", "20", "Time for map voting", FCVAR_NOTIFY);
    g_cvSurfRTVRequiredPercentage = CreateConVar("surf_rtv_percentage", "60", "Percentage of players needed for RTV", FCVAR_NOTIFY);
    
    AutoExecConfig(true, "porter_surf");
}

void InitializeDatabase()
{
    char error[255];
    g_hDatabase = SQL_Connect("porter_surf", true, error, sizeof(error));
    
    if(g_hDatabase == null)
    {
        LogError("Database Connection Failed: %s", error);
        return;
    }
    
    // Create necessary tables
    CreateTables();
}

void CreateTables()
{
    char query[1024];
    
    // Players table
    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s_players (\
        id INT NOT NULL AUTO_INCREMENT,\
        steam_id VARCHAR(32) NOT NULL,\
        name VARCHAR(64) NOT NULL,\
        points INT DEFAULT 0,\
        rank INT DEFAULT 0,\
        completions INT DEFAULT 0,\
        play_time INT DEFAULT 0,\
        PRIMARY KEY (id),\
        UNIQUE KEY (steam_id)\
    )", MYSQL_TABLE_PREFIX);
    SQL_TQuery(g_hDatabase, SQL_ErrorCallback, query);
    
    // Times table
    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s_times (\
        id INT NOT NULL AUTO_INCREMENT,\
        steam_id VARCHAR(32) NOT NULL,\
        map VARCHAR(128) NOT NULL,\
        time FLOAT NOT NULL,\
        style INT DEFAULT 0,\
        date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\
        PRIMARY KEY (id)\
    )", MYSQL_TABLE_PREFIX);
    SQL_TQuery(g_hDatabase, SQL_ErrorCallback, query);
    
    // Maps table
    Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s_maps (\
        id INT NOT NULL AUTO_INCREMENT,\
        name VARCHAR(128) NOT NULL,\
        tier INT DEFAULT 1,\
        completions INT DEFAULT 0,\
        best_time FLOAT DEFAULT NULL,\
        best_player VARCHAR(32) DEFAULT NULL,\
        PRIMARY KEY (id),\
        UNIQUE KEY (name)\
    )", MYSQL_TABLE_PREFIX);
    SQL_TQuery(g_hDatabase, SQL_ErrorCallback, query);
}

void RegisterCommands()
{
    // Surf Timer Commands
    RegConsoleCmd("sm_timer", Command_Timer, "Toggle Surf Timer");
    RegConsoleCmd("sm_rank", Command_Rank, "Show Player Rank");
    RegConsoleCmd("sm_top", Command_TopPlayers, "Show Top Players");
    
    // Map Commands
    RegConsoleCmd("sm_nominate", Command_NominateMap, "Nominate a Map");
    RegConsoleCmd("sm_rtv", Command_RockTheVote, "Rock The Vote");
    
    // Basic commands
    RegConsoleCmd("sm_surf", Command_Surf, "Open surf menu");
    RegConsoleCmd("sm_speed", Command_Speed, "Toggle speed overlay");
    RegConsoleCmd("sm_style", Command_Style, "Change surf style");
    RegConsoleCmd("sm_checkpoint", Command_Checkpoint, "Set checkpoint");
    RegConsoleCmd("sm_teleport", Command_Teleport, "Teleport to checkpoint");
    RegConsoleCmd("sm_restart", Command_Restart, "Restart current run");
    
    // Ranking commands
    RegConsoleCmd("sm_maprank", Command_MapRank, "Show map rankings");
    RegConsoleCmd("sm_points", Command_Points, "Show player points");
    
    // Map commands
    RegConsoleCmd("sm_mapinfo", Command_MapInfo, "Show current map info");
    
    // Admin commands
    RegAdminCmd("sm_settier", Command_SetTier, ADMFLAG_RCON, "Set map tier");
    RegAdminCmd("sm_resetmap", Command_ResetMap, ADMFLAG_RCON, "Reset map records");
    RegAdminCmd("sm_zones", Command_Zones, ADMFLAG_RCON, "Open zones menu");
}

void HookEvents()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_team", Event_PlayerTeam);
}

public void OnMapStart()
{
    GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
    LoadMapConfig();
    ResetMapVariables();
    InitializeZones();
    UpdateMapInfo();
}

void LoadMapConfig()
{
    char path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "cfg/sourcemod/maps/%s.cfg", g_sCurrentMap);
    if(FileExists(path))
    {
        ServerCommand("exec sourcemod/maps/%s.cfg", g_sCurrentMap);
    }
}

public Action Command_Surf(int client, int args)
{
    if(!IsValidClient(client)) return Plugin_Handled;
    
    Menu menu = new Menu(MenuHandler_Surf);
    menu.SetTitle("★ Porter's Surf Paradise ★\n \n");
    
    menu.AddItem("speed", "Speed Settings");
    menu.AddItem("style", "Style Settings");
    menu.AddItem("checkpoint", "Checkpoint System");
    menu.AddItem("stats", "Statistics");
    menu.AddItem("preferences", "Preferences");
    menu.AddItem("help", "Help & Commands");
    
    menu.Display(client, MENU_TIME_FOREVER);
    
    return Plugin_Handled;
}

public int MenuHandler_Surf(Menu menu, MenuAction action, int client, int item)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        
        if(StrEqual(info, "speed"))
        {
            ShowSpeedMenu(client);
        }
        else if(StrEqual(info, "style"))
        {
            ShowStyleMenu(client);
        }
        else if(StrEqual(info, "checkpoint"))
        {
            ShowCheckpointMenu(client);
        }
        else if(StrEqual(info, "stats"))
        {
            ShowStatsMenu(client);
        }
        else if(StrEqual(info, "preferences"))
        {
            ShowPreferencesMenu(client);
        }
        else if(StrEqual(info, "help"))
        {
            ShowHelpMenu(client);
        }
    }
    else if(action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

void ShowSpeedMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Speed);
    menu.SetTitle("Speed Settings\n \n");
    
    menu.AddItem("1.0", "Normal Speed (1.0x)");
    menu.AddItem("1.2", "Fast Speed (1.2x)");
    menu.AddItem("1.5", "Very Fast (1.5x)");
    menu.AddItem("2.0", "Extreme Speed (2.0x)");
    menu.AddItem("custom", "Custom Speed...");
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowStyleMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Style);
    menu.SetTitle("Style Settings\n \n");
    
    menu.AddItem("0", "Normal");
    menu.AddItem("1", "No Strafe");
    menu.AddItem("2", "No Acceleration");
    menu.AddItem("3", "No Boost");
    menu.AddItem("4", "No Jump");
    menu.AddItem("5", "No Speed");
    menu.AddItem("6", "Backwards");
    menu.AddItem("7", "Low Gravity");
    menu.AddItem("8", "High Gravity");
    menu.AddItem("9", "Auto Hop");
    menu.AddItem("10", "No Auto Hop");
    menu.AddItem("11", "Expert Mode");
    
    menu.ExitBackButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

void UpdateSpeedOverlay(int client)
{
    if(!g_cvSurfEnableOverlay.BoolValue || !g_bPlayerOverlay[client])
        return;

    float speed = g_fPlayerSpeed[client];
    float time = g_bTimerRunning[client] ? GetGameTime() - g_fPlayerStartTime[client] : 0.0;
    
    char text[256];
    Format(text, sizeof(text), 
        "Speed: %.1f u/s\n"
        "Time: %.3f s\n"
        "Best: %.3f s\n"
        "Style: %s\n"
        "Rank: #%d",
        speed, time, g_fPlayerBestTime[client],
        GetStyleName(g_iPlayerStyle[client]),
        g_iPlayerRank[client]);
    
    SetHudTextParams(0.02, 0.1, 0.1, 255, 255, 255, 255);
    ShowSyncHudText(client, CreateHudSynchronizer(), text);
}

char[] GetStyleName(int style)
{
    char styleName[MAX_STYLE_NAME];
    
    switch(style)
    {
        case Style_Normal: strcopy(styleName, sizeof(styleName), "Normal");
        case Style_NoStrafe: strcopy(styleName, sizeof(styleName), "No Strafe");
        case Style_NoAccel: strcopy(styleName, sizeof(styleName), "No Accel");
        case Style_NoBoost: strcopy(styleName, sizeof(styleName), "No Boost");
        case Style_NoJump: strcopy(styleName, sizeof(styleName), "No Jump");
        case Style_NoSpeed: strcopy(styleName, sizeof(styleName), "No Speed");
        case Style_Backwards: strcopy(styleName, sizeof(styleName), "Backwards");
        case Style_LowGravity: strcopy(styleName, sizeof(styleName), "Low Grav");
        case Style_HighGravity: strcopy(styleName, sizeof(styleName), "High Grav");
        case Style_AutoHop: strcopy(styleName, sizeof(styleName), "Auto Hop");
        case Style_NoAutoHop: strcopy(styleName, sizeof(styleName), "No Auto Hop");
        case Style_Expert: strcopy(styleName, sizeof(styleName), "Expert");
        default: strcopy(styleName, sizeof(styleName), "Unknown");
    }
    
    return styleName;
}

public Action Command_Timer(int client, int args)
{
    if (!g_cvSurfTimerEnabled.BoolValue) {
        ReplyToCommand(client, "[SM] Surf Timer is currently disabled.");
        return Plugin_Handled;
    }
    
    if (!g_bSurfTimerActive[client]) {
        StartSurfTimer(client);
    } else {
        StopSurfTimer(client);
    }
    
    return Plugin_Handled;
}

void StartSurfTimer(int client)
{
    g_bSurfTimerActive[client] = true;
    g_fStartTime[client] = GetGameTime();
    CPrintToChat(client, "{green}[Surf Timer] {default}Timer started!");
}

void StopSurfTimer(int client)
{
    float totalTime = GetGameTime() - g_fStartTime[client];
    g_bSurfTimerActive[client] = false;
    
    CPrintToChat(client, "{green}[Surf Timer] {default}Your time: {yellow}%.2f seconds", totalTime);
    
    // TODO: Implement time saving and ranking logic
}

public Action Command_Rank(int client, int args)
{
    if (!g_cvRankingSystem.BoolValue) {
        ReplyToCommand(client, "[SM] Ranking system is disabled.");
        return Plugin_Handled;
    }
    
    DisplayPlayerRank(client);
    return Plugin_Handled;
}

void DisplayPlayerRank(int client)
{
    // Placeholder rank display
    CPrintToChat(client, "{green}[Surf Ranks] {default}Your current rank: {yellow}#%d", g_iPlayerRank[client]);
}

public Action Command_TopPlayers(int client, int args)
{
    // TODO: Implement top players display
    CPrintToChat(client, "{green}[Surf Ranks] {default}Top players feature coming soon!");
    return Plugin_Handled;
}

public Action Command_NominateMap(int client, int args)
{
    if (!g_cvMapVoteEnabled.BoolValue) {
        ReplyToCommand(client, "[SM] Map voting is currently disabled.");
        return Plugin_Handled;
    }
    
    // TODO: Implement map nomination logic
    CPrintToChat(client, "{green}[Map Vote] {default}Map nomination feature coming soon!");
    return Plugin_Handled;
}

public Action Command_RockTheVote(int client, int args)
{
    if (!g_cvMapVoteEnabled.BoolValue) {
        ReplyToCommand(client, "[SM] Map voting is currently disabled.");
        return Plugin_Handled;
    }
    
    // TODO: Implement Rock The Vote logic
    CPrintToChat(client, "{green}[Map Vote] {default}Rock The Vote feature coming soon!");
    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client)) {
        ResetPlayerTimer(client);
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client)) {
        StopSurfTimer(client);
    }
}

void ResetPlayerTimer(int client)
{
    g_bSurfTimerActive[client] = false;
    g_fStartTime[client] = 0.0;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

public void OnClientPutInServer(int client)
{
    ResetPlayerTimer(client);
}

public void OnClientDisconnect(int client)
{
    ResetPlayerTimer(client);
}

void SavePlayerTime(int client, float time)
{
    if(!IsValidClient(client) || !g_cvSurfEnableLeaderboard.BoolValue)
        return;
        
    char query[512], steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    
    Format(query, sizeof(query), 
        "INSERT INTO %s_times (steam_id, map, time, style) VALUES ('%s', '%s', %.3f, %d) \
        ON DUPLICATE KEY UPDATE time = IF(%.3f < time, %.3f, time)",
        MYSQL_TABLE_PREFIX, steamid, g_sCurrentMap, time, g_iPlayerStyle[client], time, time);
        
    SQL_TQuery(g_hDatabase, SQL_SaveTimeCallback, query, GetClientUserId(client));
}

public void SQL_SaveTimeCallback(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == null)
    {
        LogError("SQL Error (SaveTime): %s", error);
        return;
    }
    
    int client = GetClientOfUserId(data);
    if(client == 0)
        return;
        
    UpdatePlayerStats(client);
}

void UpdatePlayerStats(int client)
{
    char query[512], steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    
    Format(query, sizeof(query), 
        "SELECT COUNT(*) as rank FROM %s_players WHERE points > \
        (SELECT points FROM %s_players WHERE steam_id = '%s')",
        MYSQL_TABLE_PREFIX, MYSQL_TABLE_PREFIX, steamid);
        
    SQL_TQuery(g_hDatabase, SQL_UpdateStatsCallback, query, GetClientUserId(client));
}

public Action Command_Checkpoint(int client, int args)
{
    if(!IsValidClient(client) || !g_cvSurfEnableCheckpoints.BoolValue)
        return Plugin_Handled;

    float pos[3], ang[3];
    GetClientAbsOrigin(client, pos);
    GetClientAbsAngles(client, ang);
    
    g_fCheckpointPos[client] = pos;
    g_fCheckpointAng[client] = ang;
    g_bHasCheckpoint[client] = true;
    g_fCheckpointTime[client] = GetGameTime();
    
    CPrintToChat(client, " {green}[Surf] {default}Checkpoint set!");
    
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
    if(!IsValidClient(client) || !g_cvSurfEnableTeleports.BoolValue || !g_bHasCheckpoint[client])
        return Plugin_Handled;

    TeleportEntity(client, g_fCheckpointPos[client], g_fCheckpointAng[client], NULL_VECTOR);
    
    CPrintToChat(client, " {green}[Surf] {default}Teleported to checkpoint!");
    
    return Plugin_Handled;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client))
    {
        g_bIsSurfing[client] = false;
        g_bHasCheckpoint[client] = false;
    }
}

bool IsOnGround(int client)
{
    return (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONGROUND) != 0;
} 