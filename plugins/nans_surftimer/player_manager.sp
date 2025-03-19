#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>

#define MAX_PLAYER_RANKS 10

enum PlayerRank {
    RANK_UNRANKED = 0,
    RANK_BEGINNER,
    RANK_INTERMEDIATE,
    RANK_ACE,
    RANK_EXPERT,
    RANK_PRO,
    RANK_LEGENDARY,
    RANK_GODLY,
    RANK_MASTER,
    RANK_GRANDMASTER
}

enum struct PlayerData {
    int ClientIndex;
    char SteamID[32];
    char Name[MAX_NAME_LENGTH];
    
    // Surf-specific stats
    int TotalPoints;
    int MapCompletions;
    int StageCompletions;
    int BonusCompletions;
    
    // Rank information
    PlayerRank CurrentRank;
    int RankProgress;
    
    // Performance tracking
    float BestMapTimes[128]; // Index by map ID
    float BestStageTimes[128][10]; // Index by map ID and stage
    float BestBonusTimes[128][5]; // Index by map ID and bonus
}

methodmap SurfPlayerManager {
    public SurfPlayerManager() {
        // Constructor
    }
    
    public void LoadPlayerData(int client) {
        // Load player data from database
        if (!IsValidClient(client)) return;
        
        char steamId[32];
        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
        
        // Fetch player data from database
        char query[512];
        Format(query, sizeof(query), 
            "SELECT points, map_completions, stage_completions, bonus_completions, rank " ...
            "FROM porter_surf_players WHERE steam_id = '%s'", steamId);
        
        // Execute query and populate player data
    }
    
    public void SavePlayerData(int client) {
        // Save player data to database
        if (!IsValidClient(client)) return;
        
        char steamId[32], name[MAX_NAME_LENGTH];
        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
        GetClientName(client, name, sizeof(name));
        
        // Prepare save query
        char query[1024];
        Format(query, sizeof(query), 
            "INSERT INTO porter_surf_players " ...
            "(steam_id, name, points, map_completions, stage_completions, bonus_completions, rank) " ...
            "VALUES ('%s', '%s', %d, %d, %d, %d, %d) " ...
            "ON DUPLICATE KEY UPDATE " ...
            "name = '%s', points = %d, map_completions = %d, " ...
            "stage_completions = %d, bonus_completions = %d, rank = %d",
            steamId, name, 
            g_iPlayerPoints[client], 
            g_iPlayerCompletions[client], 
            0, // stage completions 
            0, // bonus completions
            g_iPlayerRank[client],
            name, 
            g_iPlayerPoints[client], 
            g_iPlayerCompletions[client], 
            0, 
            0, 
            g_iPlayerRank[client]);
        
        // Execute query
    }
    
    public void UpdatePlayerRank(int client) {
        // Calculate player rank based on points and performance
        int points = g_iPlayerPoints[client];
        
        PlayerRank newRank;
        if (points < 100) newRank = RANK_BEGINNER;
        else if (points < 500) newRank = RANK_INTERMEDIATE;
        else if (points < 1000) newRank = RANK_ACE;
        else if (points < 2000) newRank = RANK_EXPERT;
        else if (points < 5000) newRank = RANK_PRO;
        else if (points < 10000) newRank = RANK_LEGENDARY;
        else if (points < 25000) newRank = RANK_GODLY;
        else if (points < 50000) newRank = RANK_MASTER;
        else newRank = RANK_GRANDMASTER;
        
        g_iPlayerRank[client] = view_as<int>(newRank);
        
        // Notify player of rank change
        if (newRank > view_as<PlayerRank>(g_iPlayerRank[client])) {
            NansPrintToChat(client, "{yellow}Rank Up! {default}You are now a {yellow}%s", GetRankName(newRank));
        }
    }
    
    public char[] GetRankName(PlayerRank rank) {
        char rankName[32];
        switch (rank) {
            case RANK_UNRANKED: strcopy(rankName, sizeof(rankName), "Unranked");
            case RANK_BEGINNER: strcopy(rankName, sizeof(rankName), "Beginner");
            case RANK_INTERMEDIATE: strcopy(rankName, sizeof(rankName), "Intermediate");
            case RANK_ACE: strcopy(rankName, sizeof(rankName), "Ace");
            case RANK_EXPERT: strcopy(rankName, sizeof(rankName), "Expert");
            case RANK_PRO: strcopy(rankName, sizeof(rankName), "Pro");
            case RANK_LEGENDARY: strcopy(rankName, sizeof(rankName), "Legendary");
            case RANK_GODLY: strcopy(rankName, sizeof(rankName), "Godly");
            case RANK_MASTER: strcopy(rankName, sizeof(rankName), "Master");
            case RANK_GRANDMASTER: strcopy(rankName, sizeof(rankName), "Grandmaster");
            default: strcopy(rankName, sizeof(rankName), "Unknown");
        }
        return rankName;
    }
    
    public void AwardPoints(int client, int points, const char[] reason) {
        g_iPlayerPoints[client] += points;
        UpdatePlayerRank(client);
        
        CPrintToChat(client, " {green}[Surf] {default}You earned {yellow}%d points {default}for %s!", points, reason);
    }
    
    public void DisplayPlayerInfo(int client, int target) {
        // Create a detailed player info menu
        Menu menu = new Menu(MenuHandler_PlayerInfo);
        menu.SetTitle("Player Information\n \n");
        
        char info[128];
        Format(info, sizeof(info), "Name: %N", target);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Rank: %s", GetRankName(view_as<PlayerRank>(g_iPlayerRank[target])));
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Points: %d", g_iPlayerPoints[target]);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        Format(info, sizeof(info), "Map Completions: %d", g_iPlayerCompletions[target]);
        menu.AddItem("", info, ITEMDRAW_DISABLED);
        
        menu.Display(client, MENU_TIME_FOREVER);
    }
}

public int MenuHandler_PlayerInfo(Menu menu, MenuAction action, int client, int item) {
    if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

// Global player manager instance
SurfPlayerManager g_SurfPlayerManager; 