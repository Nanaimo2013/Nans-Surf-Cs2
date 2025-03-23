#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define MAX_ZONES 32

public Plugin myinfo = {
    name = "Nans Surf",
    author = "Nanaimo_2013",
    description = "Core surf plugin for CS2 servers",
    version = PLUGIN_VERSION,
    url = "https://github.com/nanaimo2013/nans-surf-cs2"
};

// Zone types
enum ZoneType {
    ZONE_START = 0,
    ZONE_END,
    ZONE_CHECKPOINT,
    ZONE_BONUS_START,
    ZONE_BONUS_END,
    ZONE_STAGE_START,
    ZONE_STAGE_END
}

// Zone structure
enum struct Zone {
    ZoneType Type;
    float Point1[3];
    float Point2[3];
    int TriggerEntity;
    int BonusID;
    int StageID;
}

// Global variables
ArrayList g_Zones;
char g_CurrentMap[PLATFORM_MAX_PATH];

// Player variables
bool g_InStartZone[MAXPLAYERS + 1];
bool g_InEndZone[MAXPLAYERS + 1];
int g_CurrentStage[MAXPLAYERS + 1];
int g_CurrentBonus[MAXPLAYERS + 1];

// Forwards
Handle g_hForward_OnPlayerEnterStartZone;
Handle g_hForward_OnPlayerEnterEndZone;
Handle g_hForward_OnPlayerEnterCheckpoint;
Handle g_hForward_OnPlayerEnterStageZone;
Handle g_hForward_OnPlayerEnterBonusZone;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    // Create natives
    CreateNative("NansSurf_GetSpawnPosition", Native_GetSpawnPosition);
    CreateNative("NansSurf_GetZoneCount", Native_GetZoneCount);
    CreateNative("NansSurf_GetZonePosition", Native_GetZonePosition);
    CreateNative("NansSurf_IsInStartZone", Native_IsInStartZone);
    CreateNative("NansSurf_IsInEndZone", Native_IsInEndZone);
    CreateNative("NansSurf_GetCurrentStage", Native_GetCurrentStage);
    CreateNative("NansSurf_GetCurrentBonus", Native_GetCurrentBonus);
    
    // Create forwards
    g_hForward_OnPlayerEnterStartZone = CreateGlobalForward("NansSurf_OnPlayerEnterStartZone", ET_Ignore, Param_Cell);
    g_hForward_OnPlayerEnterEndZone = CreateGlobalForward("NansSurf_OnPlayerEnterEndZone", ET_Ignore, Param_Cell);
    g_hForward_OnPlayerEnterCheckpoint = CreateGlobalForward("NansSurf_OnPlayerEnterCheckpoint", ET_Ignore, Param_Cell, Param_Cell);
    g_hForward_OnPlayerEnterStageZone = CreateGlobalForward("NansSurf_OnPlayerEnterStageZone", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    g_hForward_OnPlayerEnterBonusZone = CreateGlobalForward("NansSurf_OnPlayerEnterBonusZone", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    
    RegPluginLibrary("NansSurf");
    return APLRes_Success;
}

public void OnPluginStart() {
    g_Zones = new ArrayList(sizeof(Zone));
    
    // Commands
    RegAdminCmd("sm_zone", Command_Zone, ADMFLAG_ROOT, "Opens the zone menu");
    RegAdminCmd("sm_addzone", Command_AddZone, ADMFLAG_ROOT, "Adds a new zone");
    RegAdminCmd("sm_delzone", Command_DeleteZone, ADMFLAG_ROOT, "Deletes a zone");
    
    // Load zones for current map if server is already running
    if (IsServerProcessing()) {
        GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
        LoadZones();
    }
}

public void OnMapStart() {
    GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
    LoadZones();
}

public void OnClientPutInServer(int client) {
    g_InStartZone[client] = false;
    g_InEndZone[client] = false;
    g_CurrentStage[client] = 0;
    g_CurrentBonus[client] = 0;
}

public void OnClientDisconnect(int client) {
    g_InStartZone[client] = false;
    g_InEndZone[client] = false;
    g_CurrentStage[client] = 0;
    g_CurrentBonus[client] = 0;
}

void LoadZones() {
    g_Zones.Clear();
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/surf/zones/%s.zones", g_CurrentMap);
    
    if (!FileExists(path)) {
        return;
    }
    
    KeyValues kv = new KeyValues("Zones");
    if (!kv.ImportFromFile(path)) {
        delete kv;
        return;
    }
    
    if (kv.GotoFirstSubKey()) {
        do {
            Zone zone;
            zone.Type = view_as<ZoneType>(kv.GetNum("type", 0));
            kv.GetVector("point1", zone.Point1);
            kv.GetVector("point2", zone.Point2);
            zone.BonusID = kv.GetNum("bonus_id", 0);
            zone.StageID = kv.GetNum("stage_id", 0);
            
            CreateZoneTrigger(zone);
            g_Zones.PushArray(zone);
        } while (kv.GotoNextKey());
    }
    
    delete kv;
}

void SaveZones() {
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/surf/zones");
    
    if (!DirExists(path)) {
        CreateDirectory(path, 511);
    }
    
    BuildPath(Path_SM, path, sizeof(path), "data/surf/zones/%s.zones", g_CurrentMap);
    
    KeyValues kv = new KeyValues("Zones");
    
    int zoneCount = g_Zones.Length;
    for (int i = 0; i < zoneCount; i++) {
        Zone zone;
        g_Zones.GetArray(i, zone);
        
        char sectionName[32];
        Format(sectionName, sizeof(sectionName), "zone_%d", i);
        kv.JumpToKey(sectionName, true);
        
        kv.SetNum("type", view_as<int>(zone.Type));
        kv.SetVector("point1", zone.Point1);
        kv.SetVector("point2", zone.Point2);
        kv.SetNum("bonus_id", zone.BonusID);
        kv.SetNum("stage_id", zone.StageID);
        
        kv.GoBack();
    }
    
    kv.ExportToFile(path);
    delete kv;
}

void CreateZoneTrigger(Zone zone) {
    int trigger = CreateEntityByName("trigger_multiple");
    if (trigger == -1) {
        return;
    }
    
    DispatchKeyValue(trigger, "spawnflags", "1");
    DispatchKeyValue(trigger, "wait", "0");
    
    DispatchSpawn(trigger);
    ActivateEntity(trigger);
    
    float minbounds[3], maxbounds[3];
    for (int i = 0; i < 3; i++) {
        minbounds[i] = zone.Point1[i] < zone.Point2[i] ? zone.Point1[i] : zone.Point2[i];
        maxbounds[i] = zone.Point1[i] > zone.Point2[i] ? zone.Point1[i] : zone.Point2[i];
    }
    
    float origin[3];
    for (int i = 0; i < 3; i++) {
        origin[i] = (minbounds[i] + maxbounds[i]) / 2.0;
    }
    
    float size[3];
    for (int i = 0; i < 3; i++) {
        size[i] = maxbounds[i] - minbounds[i];
    }
    
    TeleportEntity(trigger, origin, NULL_VECTOR, NULL_VECTOR);
    
    SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
    SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);
    SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
    
    SDKHook(trigger, SDKHook_StartTouch, OnZoneStartTouch);
    SDKHook(trigger, SDKHook_EndTouch, OnZoneEndTouch);
    
    zone.TriggerEntity = trigger;
}

public Action OnZoneStartTouch(int entity, int client) {
    if (!IsValidClient(client)) {
        return Plugin_Continue;
    }
    
    int zoneIndex = -1;
    Zone zone;
    
    for (int i = 0; i < g_Zones.Length; i++) {
        g_Zones.GetArray(i, zone);
        if (zone.TriggerEntity == entity) {
            zoneIndex = i;
            break;
        }
    }
    
    if (zoneIndex == -1) {
        return Plugin_Continue;
    }
    
    switch (zone.Type) {
        case ZONE_START: {
            g_InStartZone[client] = true;
            PrintToChat(client, " \x04[Surf]\x01 Entered start zone");
            
            Call_StartForward(g_hForward_OnPlayerEnterStartZone);
            Call_PushCell(client);
            Call_Finish();
        }
        case ZONE_END: {
            g_InEndZone[client] = true;
            PrintToChat(client, " \x04[Surf]\x01 Entered end zone");
            
            Call_StartForward(g_hForward_OnPlayerEnterEndZone);
            Call_PushCell(client);
            Call_Finish();
        }
        case ZONE_CHECKPOINT: {
            PrintToChat(client, " \x04[Surf]\x01 Checkpoint reached");
            
            Call_StartForward(g_hForward_OnPlayerEnterCheckpoint);
            Call_PushCell(client);
            Call_PushCell(zoneIndex);
            Call_Finish();
        }
        case ZONE_BONUS_START: {
            g_CurrentBonus[client] = zone.BonusID;
            PrintToChat(client, " \x04[Surf]\x01 Entered bonus %d start zone", zone.BonusID);
            
            Call_StartForward(g_hForward_OnPlayerEnterBonusZone);
            Call_PushCell(client);
            Call_PushCell(zone.BonusID);
            Call_PushCell(true);
            Call_Finish();
        }
        case ZONE_BONUS_END: {
            if (g_CurrentBonus[client] == zone.BonusID) {
                PrintToChat(client, " \x04[Surf]\x01 Completed bonus %d!", zone.BonusID);
                
                Call_StartForward(g_hForward_OnPlayerEnterBonusZone);
                Call_PushCell(client);
                Call_PushCell(zone.BonusID);
                Call_PushCell(false);
                Call_Finish();
            }
        }
        case ZONE_STAGE_START: {
            g_CurrentStage[client] = zone.StageID;
            PrintToChat(client, " \x04[Surf]\x01 Entered stage %d", zone.StageID);
            
            Call_StartForward(g_hForward_OnPlayerEnterStageZone);
            Call_PushCell(client);
            Call_PushCell(zone.StageID);
            Call_PushCell(true);
            Call_Finish();
        }
        case ZONE_STAGE_END: {
            if (g_CurrentStage[client] == zone.StageID) {
                PrintToChat(client, " \x04[Surf]\x01 Completed stage %d!", zone.StageID);
                
                Call_StartForward(g_hForward_OnPlayerEnterStageZone);
                Call_PushCell(client);
                Call_PushCell(zone.StageID);
                Call_PushCell(false);
                Call_Finish();
            }
        }
    }
    
    return Plugin_Continue;
}

public Action OnZoneEndTouch(int entity, int client) {
    if (!IsValidClient(client)) {
        return Plugin_Continue;
    }
    
    int zoneIndex = -1;
    Zone zone;
    
    for (int i = 0; i < g_Zones.Length; i++) {
        g_Zones.GetArray(i, zone);
        if (zone.TriggerEntity == entity) {
            zoneIndex = i;
            break;
        }
    }
    
    if (zoneIndex == -1) {
        return Plugin_Continue;
    }
    
    switch (zone.Type) {
        case ZONE_START: {
            g_InStartZone[client] = false;
        }
        case ZONE_END: {
            g_InEndZone[client] = false;
        }
    }
    
    return Plugin_Continue;
}

public Action Command_Zone(int client, int args) {
    if (!IsValidClient(client)) {
        return Plugin_Handled;
    }
    
    // TODO: Implement zone menu
    PrintToChat(client, " \x04[Surf]\x01 Zone menu not implemented yet");
    return Plugin_Handled;
}

public Action Command_AddZone(int client, int args) {
    if (!IsValidClient(client)) {
        return Plugin_Handled;
    }
    
    if (args < 1) {
        PrintToChat(client, " \x04[Surf]\x01 Usage: !addzone <type> [bonus_id/stage_id]");
        return Plugin_Handled;
    }
    
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    
    Zone zone;
    float eyePos[3], eyeAng[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    
    // Set default zone size
    zone.Point1 = eyePos;
    zone.Point2[0] = eyePos[0] + 128.0;
    zone.Point2[1] = eyePos[1] + 128.0;
    zone.Point2[2] = eyePos[2] + 128.0;
    
    // Determine zone type
    if (strcmp(arg, "start", false) == 0) {
        zone.Type = ZONE_START;
    } else if (strcmp(arg, "end", false) == 0) {
        zone.Type = ZONE_END;
    } else if (strcmp(arg, "checkpoint", false) == 0) {
        zone.Type = ZONE_CHECKPOINT;
    } else if (strcmp(arg, "bonus_start", false) == 0) {
        zone.Type = ZONE_BONUS_START;
        if (args >= 2) {
            GetCmdArg(2, arg, sizeof(arg));
            zone.BonusID = StringToInt(arg);
        }
    } else if (strcmp(arg, "bonus_end", false) == 0) {
        zone.Type = ZONE_BONUS_END;
        if (args >= 2) {
            GetCmdArg(2, arg, sizeof(arg));
            zone.BonusID = StringToInt(arg);
        }
    } else if (strcmp(arg, "stage_start", false) == 0) {
        zone.Type = ZONE_STAGE_START;
        if (args >= 2) {
            GetCmdArg(2, arg, sizeof(arg));
            zone.StageID = StringToInt(arg);
        }
    } else if (strcmp(arg, "stage_end", false) == 0) {
        zone.Type = ZONE_STAGE_END;
        if (args >= 2) {
            GetCmdArg(2, arg, sizeof(arg));
            zone.StageID = StringToInt(arg);
        }
    } else {
        PrintToChat(client, " \x04[Surf]\x01 Invalid zone type. Valid types: start, end, checkpoint, bonus_start, bonus_end, stage_start, stage_end");
        return Plugin_Handled;
    }
    
    CreateZoneTrigger(zone);
    g_Zones.PushArray(zone);
    SaveZones();
    
    PrintToChat(client, " \x04[Surf]\x01 Zone created successfully.");
    return Plugin_Handled;
}

public Action Command_DeleteZone(int client, int args) {
    if (!IsValidClient(client)) {
        return Plugin_Handled;
    }
    
    if (args < 1) {
        PrintToChat(client, " \x04[Surf]\x01 Usage: !delzone <index>");
        return Plugin_Handled;
    }
    
    char arg[32];
    GetCmdArg(1, arg, sizeof(arg));
    int index = StringToInt(arg) - 1;
    
    if (index < 0 || index >= g_Zones.Length) {
        PrintToChat(client, " \x04[Surf]\x01 Invalid zone index. Use !zones to see available zones.");
        return Plugin_Handled;
    }
    
    Zone zone;
    g_Zones.GetArray(index, zone);
    
    if (IsValidEntity(zone.TriggerEntity)) {
        AcceptEntityInput(zone.TriggerEntity, "Kill");
    }
    
    g_Zones.Erase(index);
    SaveZones();
    
    PrintToChat(client, " \x04[Surf]\x01 Zone deleted successfully.");
    return Plugin_Handled;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

// Native functions
public int Native_GetSpawnPosition(Handle plugin, int numParams) {
    float position[3], angles[3];
    
    // For now, return the first start zone's center position
    Zone zone;
    for (int i = 0; i < g_Zones.Length; i++) {
        g_Zones.GetArray(i, zone);
        if (zone.Type == ZONE_START) {
            for (int j = 0; j < 3; j++) {
                position[j] = (zone.Point1[j] + zone.Point2[j]) / 2.0;
            }
            angles[0] = 0.0;
            angles[1] = 0.0;
            angles[2] = 0.0;
            
            SetNativeArray(1, position, 3);
            SetNativeArray(2, angles, 3);
            return true;
        }
    }
    
    return false;
}

public int Native_GetZoneCount(Handle plugin, int numParams) {
    return g_Zones.Length;
}

public int Native_GetZonePosition(Handle plugin, int numParams) {
    int zoneIndex = GetNativeCell(1);
    if (zoneIndex < 0 || zoneIndex >= g_Zones.Length) return false;
    
    Zone zone;
    g_Zones.GetArray(zoneIndex, zone);
    
    float point1[3], point2[3];
    for (int i = 0; i < 3; i++) {
        point1[i] = zone.Point1[i];
        point2[i] = zone.Point2[i];
    }
    
    SetNativeArray(2, point1, 3);
    SetNativeArray(3, point2, 3);
    return true;
}

public int Native_IsInStartZone(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return g_InStartZone[client];
}

public int Native_IsInEndZone(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return g_InEndZone[client];
}

public int Native_GetCurrentStage(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return g_CurrentStage[client];
}

public int Native_GetCurrentBonus(Handle plugin, int numParams) {
    int client = GetNativeCell(1);
    return g_CurrentBonus[client];
} 