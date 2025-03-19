#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "nans_surftimer/zones.sp"
#include "nans_surftimer/database.sp"
#include "nans_surftimer/player_manager.sp"
#include "nans_surftimer/map_manager.sp"
#include "nans_surftimer/leaderboard.sp"
#include "nans_surftimer/replay_system.sp"

#pragma semicolon 1
#pragma newdecls required

// Plugin Info
public Plugin myinfo = 
{
    name = "Nans Surf",
    author = "Nans",
    description = "Surf plugin for CS2",
    version = "1.0.0",
    url = ""
};

// ConVars
ConVar g_cvSurfSpeed;
ConVar g_cvSurfGravity;
ConVar g_cvSurfAcceleration;
ConVar g_cvSurfAirAcceleration;
ConVar g_cvSurfStaminaJumpCost;
ConVar g_cvSurfStaminaMax;
ConVar g_cvSurfAutoBhop;

// Global Variables
int g_iPlayerStyle[MAXPLAYERS + 1];
bool g_bAutoBhop[MAXPLAYERS + 1];

// Style Definitions
enum Style
{
    Style_Normal = 0,
    Style_NoStrafe,
    Style_NoAcceleration,
    Style_NoBoost,
    Style_AutoBhop,
    Style_Sideways,
    Style_HalfSideways,
    Style_LowGravity
}

public void OnPluginStart()
{
    // Create ConVars
    g_cvSurfSpeed = CreateConVar("sm_surf_speed", "1.0", "Base movement speed multiplier");
    g_cvSurfGravity = CreateConVar("sm_surf_gravity", "0.8", "Gravity multiplier (1.0 = normal)");
    g_cvSurfAcceleration = CreateConVar("sm_surf_acceleration", "10.0", "Player acceleration");
    g_cvSurfAirAcceleration = CreateConVar("sm_surf_air_acceleration", "150.0", "Air acceleration");
    g_cvSurfStaminaJumpCost = CreateConVar("sm_surf_stamina_jump_cost", "0.0", "Stamina cost per jump");
    g_cvSurfStaminaMax = CreateConVar("sm_surf_stamina_max", "100.0", "Maximum stamina");
    g_cvSurfAutoBhop = CreateConVar("sm_surf_auto_bhop", "1", "Enable auto bunny hopping");

    // Commands
    RegConsoleCmd("sm_style", Command_Style, "Opens the style menu");
    RegConsoleCmd("sm_surf", Command_Surf, "Opens the surf menu");
    RegConsoleCmd("sm_stats", Command_Stats, "Shows player stats");
    RegConsoleCmd("sm_help", Command_Help, "Shows help menu");
    
    // Hook Events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_jump", Event_PlayerJump);
    
    // Load translations
    LoadTranslations("common.phrases");
    
    // Execute config
    AutoExecConfig(true, "nans_surf");
}

public void OnMapStart()
{
    // Set server settings
    ServerCommand("sv_airaccelerate 150");
    ServerCommand("sv_gravity 800");
    ServerCommand("sv_enablebunnyhopping 1");
    ServerCommand("sv_autobunnyhopping 1");
    ServerCommand("sv_staminamax 0");
    ServerCommand("sv_staminajumpcost 0");
    ServerCommand("sv_staminalandcost 0");
    ServerCommand("sv_accelerate 10");
    ServerCommand("sv_friction 4");
    ServerCommand("sv_maxvelocity 3500");
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        g_iPlayerStyle[client] = 0;
        g_bAutoBhop[client] = g_cvSurfAutoBhop.BoolValue;
        
        // Set client settings
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_cvSurfSpeed.FloatValue);
        SetEntityGravity(client, g_cvSurfGravity.FloatValue);
    }
}

public void OnClientDisconnect(int client)
{
    g_iPlayerStyle[client] = 0;
    g_bAutoBhop[client] = false;
}

public Action Command_Style(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x04[Surf]\x01 Style menu is currently disabled.");
    return Plugin_Handled;
}

public Action Command_Surf(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x04[Surf]\x01 Surf menu is currently disabled.");
    return Plugin_Handled;
}

public Action Command_Stats(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x04[Surf]\x01 Stats are currently disabled.");
    return Plugin_Handled;
}

public Action Command_Help(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x04[Surf]\x01 Available commands:");
    PrintToChat(client, " \x05!style\x01 - Change your surf style");
    PrintToChat(client, " \x05!surf\x01 - Open the surf menu");
    PrintToChat(client, " \x05!stats\x01 - View your statistics");
    PrintToChat(client, " \x05!help\x01 - Show this help message");
    return Plugin_Handled;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        // Set default movement settings
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
        
        // Apply style settings
        switch (g_iPlayerStyle[client])
        {
            case Style_AutoBhop:
            {
                g_bAutoBhop[client] = true;
            }
            case Style_LowGravity:
            {
                SetEntityGravity(client, 0.5);
            }
            default:
            {
                g_bAutoBhop[client] = false;
                SetEntityGravity(client, 1.0);
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
    {
        if (g_bAutoBhop[client])
        {
            SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
        }
    }
    return Plugin_Continue;
}

stock void NansPrintToChat(int client, const char[] format, any ...)
{
    char buffer[291];
    VFormat(buffer, sizeof(buffer), format, 3);
    PrintToChat(client, " \x04[Surf]\x01 %s", buffer);
}

stock char[] GetStyleName(int style)
{
    char styleName[32];
    switch (style)
    {
        case Style_Normal: strcopy(styleName, sizeof(styleName), "Normal");
        case Style_NoStrafe: strcopy(styleName, sizeof(styleName), "No Strafe");
        case Style_NoAcceleration: strcopy(styleName, sizeof(styleName), "No Acceleration");
        case Style_NoBoost: strcopy(styleName, sizeof(styleName), "No Boost");
        case Style_AutoBhop: strcopy(styleName, sizeof(styleName), "Auto Bhop");
        case Style_Sideways: strcopy(styleName, sizeof(styleName), "Sideways");
        case Style_HalfSideways: strcopy(styleName, sizeof(styleName), "Half Sideways");
        case Style_LowGravity: strcopy(styleName, sizeof(styleName), "Low Gravity");
        default: strcopy(styleName, sizeof(styleName), "Unknown");
    }
    return styleName;
}
