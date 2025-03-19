#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>

#define MAX_MAP_TIERS 5
#define MAX_STAGES_PER_MAP 10
#define MAX_BONUSES_PER_MAP 5

enum MapTier {
    TIER_VERY_EASY = 1,
    TIER_EASY,
    TIER_MEDIUM,
    TIER_HARD,
    TIER_VERY_HARD
}

enum struct MapInfo {
    char MapName[128];
    MapTier Tier;
    int StageCount;
    int BonusCount;
    float BestMapTime;
    char BestMapPlayer[MAX_NAME_LENGTH];
    int MapCompletions;
}

enum struct StageInfo {
    int StageNumber;
    float BestStageTime;
    char BestStagePlayer[MAX_NAME_LENGTH];
    int StageCompletions;
}

enum struct BonusInfo {
    int BonusNumber;
    float BestBonusTime;
    char BestBonusPlayer[MAX_NAME_LENGTH];
    int BonusCompletions;
}

methodmap SurfMapManager {
    public SurfMapManager() {
        // Constructor
    }
    
    public void LoadMapInfo(const char[] mapName) {
        // Load map information from database
        char query[512];
        Format(query, sizeof(query), 
            "SELECT tier, stages, bonuses, best_time, best_player, completions " ...
            "FROM porter_surf_maps WHERE name = '%s'", mapName);
        
        // Execute query and populate MapInfo
    }
    
    public void SaveMapInfo(MapInfo mapInfo) {
        // Save map information to database
        char query[1024];
        Format(query, sizeof(query), 
            "INSERT INTO porter_surf_maps " ...
            "(name, tier, stages, bonuses, best_time, best_player, completions) " ...
            "VALUES ('%s', %d, %d, %d, %.3f, '%s', %d) " ...
            "ON DUPLICATE KEY UPDATE " ...
            "tier = %d, stages = %d, bonuses = %d, " ...
            "best_time = IF(%.3f < best_time, %.3f, best_time), " ...
            "best_player = IF(%.3f < best_time, '%s', best_player), " ...
            "completions = completions + %d",
            mapInfo.MapName, mapInfo.Tier, mapInfo.StageCount, mapInfo.BonusCount, 
            mapInfo.BestMapTime, mapInfo.BestMapPlayer, mapInfo.MapCompletions,
            mapInfo.Tier, mapInfo.StageCount, mapInfo.BonusCount,
            mapInfo.BestMapTime, mapInfo.BestMapTime,
            mapInfo.BestMapTime, mapInfo.BestMapPlayer,
            mapInfo.MapCompletions);
        
        // Execute query
    }
    
    public void DisplayMapInfo(int client, const char[] mapName) {
        Menu menu = new Menu(MenuHandler_MapInfo);
        menu.SetTitle("Map Information - %s\n \n", mapName);
        
        MapInfo mapInfo;
        this.LoadMapInfo(mapName);
        
        char info[128];
        Format(info, sizeof(info), "Tier: %s", GetMapTierName(mapInfo.Tier));
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Stages: %d", mapInfo.StageCount);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Bonuses: %d", mapInfo.BonusCount);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Best Time: %.3f by %s", mapInfo.BestMapTime, mapInfo.BestMapPlayer);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Completions: %d", mapInfo.MapCompletions);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    public void DisplayStageInfo(int client, const char[] mapName, int stageNumber) {
        Menu menu = new Menu(MenuHandler_StageInfo);
        menu.SetTitle("Stage %d Information - %s\n \n", stageNumber, mapName);
        
        StageInfo stageInfo;
        this.LoadStageInfo(mapName, stageNumber, stageInfo);
        
        char info[128];
        Format(info, sizeof(info), "Best Stage Time: %.3f by %s", stageInfo.BestStageTime, stageInfo.BestStagePlayer);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Stage Completions: %d", stageInfo.StageCompletions);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    public void DisplayBonusInfo(int client, const char[] mapName, int bonusNumber) {
        Menu menu = new Menu(MenuHandler_BonusInfo);
        menu.SetTitle("Bonus %d Information - %s\n \n", bonusNumber, mapName);
        
        BonusInfo bonusInfo;
        this.LoadBonusInfo(mapName, bonusNumber, bonusInfo);
        
        char info[128];
        Format(info, sizeof(info), "Best Bonus Time: %.3f by %s", bonusInfo.BestBonusTime, bonusInfo.BestBonusPlayer);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Bonus Completions: %d", bonusInfo.BonusCompletions);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    public void LoadStageInfo(const char[] mapName, int stageNumber, StageInfo stageInfo) {
        char query[512];
        Format(query, sizeof(query), 
            "SELECT best_time, best_player, completions " ...
            "FROM porter_surf_stage_times " ...
            "WHERE map = '%s' AND stage = %d", mapName, stageNumber);
        
        // Execute query and populate StageInfo
    }
    
    public void LoadBonusInfo(const char[] mapName, int bonusNumber, BonusInfo bonusInfo) {
        char query[512];
        Format(query, sizeof(query), 
            "SELECT best_time, best_player, completions " ...
            "FROM porter_surf_bonus_times " ...
            "WHERE map = '%s' AND bonus = %d", mapName, bonusNumber);
        
        // Execute query and populate BonusInfo
    }
    
    public char[] GetMapTierName(MapTier tier) {
        char tierName[32];
        switch (tier) {
            case TIER_VERY_EASY: strcopy(tierName, sizeof(tierName), "Very Easy");
            case TIER_EASY: strcopy(tierName, sizeof(tierName), "Easy");
            case TIER_MEDIUM: strcopy(tierName, sizeof(tierName), "Medium");
            case TIER_HARD: strcopy(tierName, sizeof(tierName), "Hard");
            case TIER_VERY_HARD: strcopy(tierName, sizeof(tierName), "Very Hard");
            default: strcopy(tierName, sizeof(tierName), "Unknown");
        }
        return tierName;
    }
    
    public void ListIncompleteMaps(int client) {
        Menu menu = new Menu(MenuHandler_IncompleteMaps);
        menu.SetTitle("Incomplete Maps\n \n");
        
        char query[512];
        Format(query, sizeof(query), 
            "SELECT name FROM porter_surf_maps " ...
            "WHERE completions = 0 ORDER BY tier");
        
        // Execute query and add menu items
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    public void ListIncompleteStages(int client, const char[] mapName) {
        Menu menu = new Menu(MenuHandler_IncompleteStages);
        menu.SetTitle("Incomplete Stages - %s\n \n", mapName);
        
        char query[512];
        Format(query, sizeof(query), 
            "SELECT stage FROM porter_surf_stage_times " ...
            "WHERE map = '%s' AND completions = 0", mapName);
        
        // Execute query and add menu items
        menu.Display(client, MENU_TIME_FOREVER);
    }
    
    public void ListIncompleteBonuses(int client, const char[] mapName) {
        Menu menu = new Menu(MenuHandler_IncompleteBonuses);
        menu.SetTitle("Incomplete Bonuses - %s\n \n", mapName);
        
        char query[512];
        Format(query, sizeof(query), 
            "SELECT bonus FROM porter_surf_bonus_times " ...
            "WHERE map = '%s' AND completions = 0", mapName);
        
        // Execute query and add menu items
        menu.Display(client, MENU_TIME_FOREVER);
    }
}

public int MenuHandler_MapInfo(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public int MenuHandler_StageInfo(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public int MenuHandler_BonusInfo(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public int MenuHandler_IncompleteMaps(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_Select) {
        char mapName[128];
        menu.GetItem(item, mapName, sizeof(mapName));
        
        // Show map details or start map
        g_SurfMapManager.DisplayMapInfo(client, mapName);
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public int MenuHandler_IncompleteStages(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_Select) {
        char stageStr[16];
        menu.GetItem(item, stageStr, sizeof(stageStr));
        int stageNumber = StringToInt(stageStr);
        
        // Show stage details or start stage
        g_SurfMapManager.DisplayStageInfo(client, g_sCurrentMap, stageNumber);
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

public int MenuHandler_IncompleteBonuses(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_Select) {
        char bonusStr[16];
        menu.GetItem(item, bonusStr, sizeof(bonusStr));
        int bonusNumber = StringToInt(bonusStr);
        
        // Show bonus details or start bonus
        g_SurfMapManager.DisplayBonusInfo(client, g_sCurrentMap, bonusNumber);
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

// Global map manager instance
SurfMapManager g_SurfMapManager; 