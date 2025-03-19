#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>
#include <clientprefs>
#include <mapchooser>
#include <timer>
#include <cstrike>
#include "nans_surftimer/zones.sp"
#include "nans_surftimer/database.sp"
#include "nans_surftimer/player_manager.sp"
#include "nans_surftimer/leaderboard.sp"
#include "nans_surftimer/replay_system.sp"
#include "nans_surftimer/map_manager.sp"

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
    Style_Expert,
    Style_Turbo,
    Style_Sideways,
    Style_HalfSideways
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

// New global variables
ArrayList g_hLoadedZones;
int g_iCurrentZoneType[MAXPLAYERS + 1];

// Color Definitions
enum NansColor {
    NANS_DEFAULT = 0,
    NANS_GREEN,
    NANS_RED,
    NANS_YELLOW,
    NANS_BLUE,
    NANS_PURPLE,
    NANS_ORANGE,
    NANS_LIGHTBLUE,
    NANS_WHITE,
    NANS_GRAY
}

// Color Codes for Chat
char g_sNansColorCodes[][] = {
    "\x01",   // Default
    "\x04",   // Green
    "\x02",   // Red
    "\x03",   // Yellow
    "\x0B",   // Blue
    "\x0E",   // Purple
    "\x10",   // Orange
    "\x0C",   // Light Blue
    "\x07",   // White
    "\x08"    // Gray
};

// Color Formatting Function
void NansPrintToChat(int client, const char[] format, any ...)
{
    char buffer[512];
    char formattedBuffer[512];
    VFormat(buffer, sizeof(buffer), format, 3);
    
    // Replace color placeholders with more comprehensive replacements
    ReplaceString(buffer, sizeof(buffer), "{default}", g_sNansColorCodes[NANS_DEFAULT]);
    ReplaceString(buffer, sizeof(buffer), "{white}", g_sNansColorCodes[NANS_WHITE]);
    ReplaceString(buffer, sizeof(buffer), "{gray}", g_sNansColorCodes[NANS_GRAY]);
    ReplaceString(buffer, sizeof(buffer), "{green}", g_sNansColorCodes[NANS_GREEN]);
    ReplaceString(buffer, sizeof(buffer), "{red}", g_sNansColorCodes[NANS_RED]);
    ReplaceString(buffer, sizeof(buffer), "{yellow}", g_sNansColorCodes[NANS_YELLOW]);
    ReplaceString(buffer, sizeof(buffer), "{blue}", g_sNansColorCodes[NANS_BLUE]);
    ReplaceString(buffer, sizeof(buffer), "{purple}", g_sNansColorCodes[NANS_PURPLE]);
    ReplaceString(buffer, sizeof(buffer), "{orange}", g_sNansColorCodes[NANS_ORANGE]);
    ReplaceString(buffer, sizeof(buffer), "{lightblue}", g_sNansColorCodes[NANS_LIGHTBLUE]);
    
    // Prepend plugin tag with green color
    Format(formattedBuffer, sizeof(formattedBuffer), "%s[Surf] %s", 
        g_sNansColorCodes[NANS_GREEN], buffer);
    
    PrintToChat(client, formattedBuffer);
}

// Broadcast version
void NansPrintToChatAll(const char[] format, any ...)
{
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            NansPrintToChat(i, buffer);
        }
    }
}

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
    
    // Initialize global zone list
    g_hLoadedZones = new ArrayList(sizeof(ZoneData));
    
    // Initialize database system
    g_SurfDatabase = new SurfDatabase();
    g_SurfZones = new SurfZones();
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
    RegConsoleCmd("sm_zones", Command_Zones, ADMFLAG_RCON, "Open zones menu");
    
    // Add zone reload command
    RegAdminCmd("sm_reloadzones", Command_ReloadZones, ADMFLAG_RCON, "Reload map zones");
    
    // Player Info Commands
    RegConsoleCmd("sm_playerinfo", Command_PlayerInfo, "Show player information");
    RegConsoleCmd("sm_ranks", Command_Ranks, "Show player ranks");
    
    // Leaderboard Commands
    RegConsoleCmd("sm_surftop", Command_SurfTop, "Show surf top players");
    
    // Map and Stage Commands
    RegConsoleCmd("sm_minfo", Command_MapInfo, "Show map information");
    RegConsoleCmd("sm_incomplete", Command_Incomplete, "Show incomplete maps, stages, or bonuses");
    RegConsoleCmd("sm_routes", Command_Routes, "Show map routes");
    
    // Replay Commands
    RegConsoleCmd("sm_replay", Command_Replay, "Manage replays");
    
    // Checkpoint and Stage Commands
    RegConsoleCmd("sm_cpr", Command_CheckpointRecord, "Show checkpoint record");
    RegConsoleCmd("sm_stuck", Command_Stuck, "Restart current stage");
    RegConsoleCmd("sm_repeat", Command_RepeatStage, "Repeat current stage");
    
    // Style Commands
    RegConsoleCmd("sm_turbo", Command_TurboStyle, "Enable Turbo style");
    RegConsoleCmd("sm_sw", Command_SWStyle, "Enable Sideways style");
    RegConsoleCmd("sm_hsw", Command_HSWStyle, "Enable Half-Sideways style");
    RegConsoleCmd("sm_lg", Command_LowGravStyle, "Enable Low Gravity style");
    
    // New short-form commands
    RegConsoleCmd("sm_re", Command_RepeatStage, "Repeat current stage (short form)");
    RegConsoleCmd("sm_st", Command_Stuck, "Restart current stage or map (short form)");
    RegConsoleCmd("sm_r", Command_Restart, "Restart current run (short form)");
    RegConsoleCmd("sm_cp", Command_Checkpoint, "Set checkpoint (short form)");
    RegConsoleCmd("sm_tp", Command_Teleport, "Teleport to checkpoint (short form)");
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
    
    // Clear existing zones
    g_hLoadedZones.Clear();
    
    // Load zones for current map
    g_SurfZones.LoadZonesFromMap(g_sCurrentMap);
    
    // Optional: Create zone configuration if not exists
    char zonePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, zonePath, sizeof(zonePath), "data/surftimer/maps/%s_zones.cfg", g_sCurrentMap);
    
    if (!FileExists(zonePath)) {
        g_SurfZones.CreateZoneConfiguration(g_sCurrentMap);
    }
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
        case Style_Turbo: strcopy(styleName, sizeof(styleName), "Turbo");
        case Style_Sideways: strcopy(styleName, sizeof(styleName), "Sideways");
        case Style_HalfSideways: strcopy(styleName, sizeof(styleName), "Half-Sideways");
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
    NansPrintToChat(client, "Timer started!");
}

void StopSurfTimer(int client)
{
    float totalTime = GetGameTime() - g_fStartTime[client];
    g_bSurfTimerActive[client] = false;
    
    NansPrintToChat(client, "Your time: %.2f seconds", totalTime);
    
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
    NansPrintToChat(client, "Your current rank: #%d", g_iPlayerRank[client]);
}

public Action Command_TopPlayers(int client, int args)
{
    // TODO: Implement top players display
    NansPrintToChat(client, "Top players feature coming soon!");
    return Plugin_Handled;
}

public Action Command_NominateMap(int client, int args)
{
    if (!g_cvMapVoteEnabled.BoolValue) {
        ReplyToCommand(client, "[SM] Map voting is currently disabled.");
        return Plugin_Handled;
    }
    
    // TODO: Implement map nomination logic
    NansPrintToChat(client, "Map nomination feature coming soon!");
    return Plugin_Handled;
}

public Action Command_RockTheVote(int client, int args)
{
    if (!g_cvMapVoteEnabled.BoolValue) {
        ReplyToCommand(client, "[SM] Map voting is currently disabled.");
        return Plugin_Handled;
    }
    
    // TODO: Implement Rock The Vote logic
    NansPrintToChat(client, "Rock The Vote feature coming soon!");
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

    // If player is in a checkpoint zone, automatically save checkpoint
    if (g_iCurrentZoneType[client] == view_as<int>(ZONE_CHECKPOINT)) {
        float pos[3], ang[3];
        GetClientAbsOrigin(client, pos);
        GetClientAbsAngles(client, ang);
        
        g_fCheckpointPos[client] = pos;
        g_fCheckpointAng[client] = ang;
        g_bHasCheckpoint[client] = true;
        g_fCheckpointTime[client] = GetGameTime() - g_fStartTime[client];
        
        NansPrintToChat(client, "Checkpoint saved!");
    } else {
        NansPrintToChat(client, "You must be in a checkpoint zone to save a checkpoint.");
    }
    
    return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
    if(!IsValidClient(client) || !g_cvSurfEnableTeleports.BoolValue || !g_bHasCheckpoint[client])
        return Plugin_Handled;

    TeleportEntity(client, g_fCheckpointPos[client], g_fCheckpointAng[client], NULL_VECTOR);
    
    NansPrintToChat(client, "Teleported to checkpoint!");
    
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

// Add zone detection to player movement hook
public void OnPlayerRunCmd(int client, int buttons, int impulse, float vel[3], float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, int mouse[2])
{
    if (!IsValidClient(client)) return;
    
    // Detect current zone
    ZoneType currentZoneType = g_SurfZones.GetPlayerCurrentZoneType(client);
    g_iCurrentZoneType[client] = view_as<int>(currentZoneType);
    
    // Timer and zone logic
    switch (currentZoneType)
    {
        case ZONE_START:
        {
            if (!g_bInStartZone[client]) {
                g_bInStartZone[client] = true;
                OnPlayerEnterStartZone(client);
            }
        }
        case ZONE_END:
        {
            if (!g_bInEndZone[client]) {
                g_bInEndZone[client] = true;
                OnPlayerEnterEndZone(client);
            }
        }
        case ZONE_CHECKPOINT:
        {
            OnPlayerEnterCheckpointZone(client);
        }
    }
}

void OnPlayerEnterStartZone(int client)
{
    // Reset timer if not already running
    if (!g_bSurfTimerActive[client]) {
        StartSurfTimer(client);
    }
    
    // Optional: Provide visual or sound feedback
    NansPrintToChat(client, "Entered start zone. Timer started!");
}

void OnPlayerEnterEndZone(int client)
{
    // Stop timer and save time
    if (g_bSurfTimerActive[client]) {
        float totalTime = GetGameTime() - g_fStartTime[client];
        StopSurfTimer(client);
        
        // Save player's time
        SavePlayerTime(client, totalTime);
        
        // Check for personal best
        float personalBest = g_SurfDatabase.GetPersonalBest(g_sCurrentMap, g_iPlayerStyle[client]);
        if (totalTime < personalBest || personalBest == 0.0) {
            NansPrintToChat(client, "New Personal Best! Time: %.2f seconds", totalTime);
        }
    }
}

void OnPlayerEnterCheckpointZone(int client)
{
    // Optional: Implement checkpoint saving logic
    if (g_bSurfTimerActive[client]) {
        float checkpointTime = GetGameTime() - g_fStartTime[client];
        g_fPlayerCheckpointTime[client] = checkpointTime;
        
        NansPrintToChat(client, "Checkpoint reached at %.2f seconds", checkpointTime);
    }
}

// Add a command to reload zones
public Action Command_ReloadZones(int client, int args)
{
    g_SurfZones.LoadZonesFromMap(g_sCurrentMap);
    NansPrintToChat(client, "Zones reloaded for map %s", g_sCurrentMap);
    return Plugin_Handled;
}

void UpdateMapInfo()
{
    // Implementation of UpdateMapInfo function
}

void ResetMapVariables()
{
    // Implementation of ResetMapVariables function
}

void InitializeZones()
{
    // Implementation of InitializeZones function
}

void ShowCheckpointMenu(int client)
{
    // Implementation of ShowCheckpointMenu function
}

void ShowStatsMenu(int client)
{
    // Implementation of ShowStatsMenu function
}

void ShowPreferencesMenu(int client)
{
    // Implementation of ShowPreferencesMenu function
}

void ShowHelpMenu(int client)
{
    // Implementation of ShowHelpMenu function
}

void ShowCheckpointMenu(int client)
{
    // Implementation of ShowCheckpointMenu function
}

void ShowStatsMenu(int client)
{
    // Implementation of ShowStatsMenu function
}

void ShowPreferencesMenu(int client)
{
    // Implementation of ShowPreferencesMenu function
}

void ShowHelpMenu(int client)
{
    // Implementation of ShowHelpMenu function
}

void ShowCheckpointMenu(int client)
{
    // Implementation of ShowCheckpointMenu function
}

void ShowStatsMenu(int client)
{
    // Implementation of ShowStatsMenu function
}

void ShowPreferencesMenu(int client)
{
    // Implementation of ShowPreferencesMenu function
}

void ShowHelpMenu(int client)
{
    // Implementation of ShowHelpMenu function
}

// New command implementations
public Action Command_PlayerInfo(int client, int args)
{
    if (args < 1) {
        // Show own info
        g_SurfPlayerManager.DisplayPlayerInfo(client, client);
        return Plugin_Handled;
    }
    
    // Get target player
    char targetName[MAX_NAME_LENGTH];
    GetCmdArg(1, targetName, sizeof(targetName));
    
    int target = FindTarget(client, targetName, true, false);
    if (target > 0) {
        g_SurfPlayerManager.DisplayPlayerInfo(client, target);
    }
    
    return Plugin_Handled;
}

public Action Command_Ranks(int client, int args)
{
    Menu menu = new Menu(MenuHandler_Ranks);
    menu.SetTitle("Player Ranks\n \n");
    
    menu.AddItem("", "Unranked");
    menu.AddItem("", "Beginner");
    menu.AddItem("", "Intermediate");
    menu.AddItem("", "Ace");
    menu.AddItem("", "Expert");
    menu.AddItem("", "Pro");
    menu.AddItem("", "Legendary");
    menu.AddItem("", "Godly");
    menu.AddItem("", "Master");
    menu.AddItem("", "Grandmaster");
    
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_Ranks(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        // Show players with this rank
        char rankName[32];
        menu.GetItem(item, "", 0, _, rankName, sizeof(rankName));
        
        // Fetch and display players with this rank
        char query[512];
        Format(query, sizeof(query), 
            "SELECT name FROM porter_surf_players " ...
            "WHERE rank_name = '%s' ORDER BY points DESC LIMIT 10", rankName);
        
        // Execute query and show results
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public Action Command_Top(int client, int args)
{
    g_SurfLeaderboard.DisplayLeaderboard(client, LEADERBOARD_TOTAL_POINTS);
    return Plugin_Handled;
}

public Action Command_SurfTop(int client, int args)
{
    g_SurfLeaderboard.DisplayLeaderboard(client, LEADERBOARD_MAP_COMPLETIONS);
    return Plugin_Handled;
}

public Action Command_MapInfo(int client, int args)
{
    if (args < 1) {
        // Show current map info
        g_SurfMapManager.DisplayMapInfo(client, g_sCurrentMap);
        return Plugin_Handled;
    }
    
    // Get map name
    char mapName[128];
    GetCmdArg(1, mapName, sizeof(mapName));
    
    g_SurfMapManager.DisplayMapInfo(client, mapName);
    return Plugin_Handled;
}

public Action Command_Incomplete(int client, int args)
{
    if (args < 1) {
        // List incomplete maps
        g_SurfMapManager.ListIncompleteMaps(client);
        return Plugin_Handled;
    }
    
    char arg[16];
    GetCmdArg(1, arg, sizeof(arg));
    
    if (StrEqual(arg, "s", false)) {
        // List incomplete stages for current map
        g_SurfMapManager.ListIncompleteStages(client, g_sCurrentMap);
    }
    else if (StrEqual(arg, "b", false)) {
        // List incomplete bonuses for current map
        g_SurfMapManager.ListIncompleteBonuses(client, g_sCurrentMap);
    }
    
    return Plugin_Handled;
}

public Action Command_Routes(int client, int args)
{
    // Show multiple map routes/variations
    Menu menu = new Menu(MenuHandler_Routes);
    menu.SetTitle("Map Routes - %s\n \n", g_sCurrentMap);
    
    // Fetch and display map routes from database
    char query[512];
    Format(query, sizeof(query), 
        "SELECT route_name FROM porter_surf_map_routes " ...
        "WHERE map = '%s'", g_sCurrentMap);
    
    // Execute query and add menu items
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_Routes(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char routeName[128];
        menu.GetItem(item, routeName, sizeof(routeName));
        
        // Load and start selected route
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public Action Command_Replay(int client, int args)
{
    Menu menu = new Menu(MenuHandler_Replay);
    menu.SetTitle("Replay System\n \n");
    
    menu.AddItem("map", "Main Map Replay");
    menu.AddItem("stage", "Stage Replay");
    menu.AddItem("bonus", "Bonus Replay");
    menu.AddItem("practice", "Practice Replay");
    
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_Replay(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select) {
        char replayType[16];
        menu.GetItem(item, replayType, sizeof(replayType));
        
        if (StrEqual(replayType, "map")) {
            g_SurfReplaySystem.ListReplays(client, REPLAY_MAIN_MAP);
        }
        else if (StrEqual(replayType, "stage")) {
            g_SurfReplaySystem.ListReplays(client, REPLAY_STAGE);
        }
        else if (StrEqual(replayType, "bonus")) {
            g_SurfReplaySystem.ListReplays(client, REPLAY_BONUS);
        }
        else if (StrEqual(replayType, "practice")) {
            g_SurfReplaySystem.ListReplays(client, REPLAY_PRACTICE);
        }
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public Action Command_CheckpointRecord(int client, int args)
{
    // Show checkpoint record for current map/stage
    char query[512];
    Format(query, sizeof(query), 
        "SELECT name, checkpoint_time FROM porter_surf_checkpoint_times " ...
        "WHERE map = '%s' ORDER BY checkpoint_time ASC LIMIT 10", 
        g_sCurrentMap);
    
    // Execute query and display results
    return Plugin_Handled;
}

public Action Command_Stuck(int client, int args)
{
    // Restart current stage or map
    if (g_iCurrentZoneType[client] == view_as<int>(ZONE_STAGE)) {
        // Teleport to stage start
        // Implement stage restart logic
    } else {
        // Teleport to map start
        TeleportEntity(client, g_fMapStartPos, NULL_VECTOR, NULL_VECTOR);
    }
    
    return Plugin_Handled;
}

public Action Command_RepeatStage(int client, int args)
{
    // Repeat current stage
    if (g_iCurrentZoneType[client] == view_as<int>(ZONE_STAGE)) {
        // Teleport to stage start
        // Implement stage repeat logic
    } else {
        NansPrintToChat(client, "You are not in a stage zone.");
    }
    
    return Plugin_Handled;
}

public Action Command_TurboStyle(int client, int args)
{
    // Implement unique Turbo surf style
    // Left click to accelerate, right click to fall faster
    g_iPlayerStyle[client] = view_as<int>(Style_Turbo);
    NansPrintToChat(client, "Turbo style enabled!");
    return Plugin_Handled;
}

public Action Command_SWStyle(int client, int args)
{
    g_iPlayerStyle[client] = view_as<int>(Style_Sideways);
    NansPrintToChat(client, "Sideways style enabled!");
    return Plugin_Handled;
}

public Action Command_HSWStyle(int client, int args)
{
    g_iPlayerStyle[client] = view_as<int>(Style_HalfSideways);
    NansPrintToChat(client, "Half-Sideways style enabled!");
    return Plugin_Handled;
}

public Action Command_LowGravStyle(int client, int args)
{
    g_iPlayerStyle[client] = view_as<int>(Style_LowGravity);
    NansPrintToChat(client, "Low Gravity style enabled!");
    return Plugin_Handled;
}

public Action Command_Restart(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    // Teleport to map start
    TeleportEntity(client, g_fMapStartPos, NULL_VECTOR, NULL_VECTOR);
    
    // Reset timer
    g_bSurfTimerActive[client] = false;
    g_fStartTime[client] = 0.0;
    g_bHasCheckpoint[client] = false;
    
    NansPrintToChat(client, "Run restarted!");
    
    return Plugin_Handled;
} 