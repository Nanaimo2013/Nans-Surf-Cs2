#if defined _nans_surf_discord_included
    #endinput
#endif
#define _nans_surf_discord_included

/**
 * Called when a Discord message is received.
 *
 * @param author    Author of the message.
 * @param message   Content of the message.
 * @param channel   Channel the message was sent in.
 */
forward void NansSurfDiscord_OnMessageReceived(const char[] author, const char[] message, const char[] channel);

/**
 * Called when a record is announced.
 *
 * @param client        Client index.
 * @param time          Time achieved (in seconds).
 * @param rank          Player's rank.
 * @param isPB          Whether this was a personal best.
 * @noreturn
 */
forward void NansSurfDiscord_OnRecordAnnounced(int client, float time, int rank, bool isPB);

/**
 * Sends a message to the configured Discord channel.
 *
 * @param message   Message to send.
 * @param channel   Optional channel to send to (uses default if empty).
 * @return          True if message was sent, false otherwise.
 */
native bool NansSurfDiscord_SendMessage(const char[] message, const char[] channel = "");

/**
 * Gets a player's stats in JSON format.
 *
 * @param steamId   Player's Steam ID.
 * @param buffer    Buffer to store the JSON response.
 * @param maxlen    Maximum length of the buffer.
 * @return          True if stats were retrieved, false otherwise.
 */
native bool NansSurfDiscord_GetPlayerStats(const char[] steamId, char[] buffer, int maxlen);

/**
 * Gets top players in JSON format.
 *
 * @param limit     Number of players to retrieve (max 100).
 * @param buffer    Buffer to store the JSON response.
 * @param maxlen    Maximum length of the buffer.
 * @return          True if stats were retrieved, false otherwise.
 */
native bool NansSurfDiscord_GetTopPlayers(int limit, char[] buffer, int maxlen);

/**
 * Gets server info in JSON format.
 *
 * @param buffer    Buffer to store the JSON response.
 * @param maxlen    Maximum length of the buffer.
 * @return          True if info was retrieved, false otherwise.
 */
native bool NansSurfDiscord_GetServerInfo(char[] buffer, int maxlen);

/**
 * Gets map info in JSON format.
 *
 * @param map       Map name.
 * @param buffer    Buffer to store the JSON response.
 * @param maxlen    Maximum length of the buffer.
 * @return          True if info was retrieved, false otherwise.
 */
native bool NansSurfDiscord_GetMapInfo(const char[] map, char[] buffer, int maxlen);

/**
 * Announces a record to Discord.
 *
 * @param client    Client index.
 * @param time      Time achieved (in seconds).
 * @param rank      Player's rank.
 * @param isPB      Whether this was a personal best.
 * @return          True if announced successfully, false otherwise.
 */
native bool NansSurfDiscord_AnnounceRecord(int client, float time, int rank, bool isPB);

// Individual player data
native int NansSurfDiscord_GetPlayerRank(const char[] steamId);
native float NansSurfDiscord_GetPlayerBestTime(const char[] steamId);
native int NansSurfDiscord_GetPlayerTotalRuns(const char[] steamId);
native bool NansSurfDiscord_GetPlayerName(const char[] steamId, char[] buffer, int maxlen);
native bool NansSurfDiscord_IsPlayerOnline(const char[] steamId);

// Individual map data
native float NansSurfDiscord_GetMapRecord(const char[] map);
native bool NansSurfDiscord_GetMapRecordHolder(const char[] map, char[] buffer, int maxlen);
native int NansSurfDiscord_GetMapCompletions(const char[] map);
native float NansSurfDiscord_GetMapAverageTime(const char[] map);

// Server data
native int NansSurfDiscord_GetOnlinePlayerCount();
native int NansSurfDiscord_GetActivePlayerCount();
native int NansSurfDiscord_GetTotalRankedPlayers();
native bool NansSurfDiscord_GetCurrentMap(char[] buffer, int maxlen);

// Leaderboard data
native bool NansSurfDiscord_GetTopTimes(const char[] map, int limit, char[] buffer, int maxlen);
native bool NansSurfDiscord_GetRecentRecords(int limit, char[] buffer, int maxlen);
native bool NansSurfDiscord_GetPlayerPosition(const char[] steamId, const char[] map, int &position, float &time);

// Utility functions
native bool NansSurfDiscord_FormatTime(float time, char[] buffer, int maxlen);
native bool NansSurfDiscord_GetFormattedRank(int rank, char[] buffer, int maxlen);

public SharedPlugin __pl_nans_surf_discord = {
    name = "NansSurfDiscord",
    file = "NansSurfDiscord.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_nans_surf_discord_SetNTVOptional() {
    // Combined data endpoints
    MarkNativeAsOptional("NansSurfDiscord_SendMessage");
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerStats");
    MarkNativeAsOptional("NansSurfDiscord_GetTopPlayers");
    MarkNativeAsOptional("NansSurfDiscord_GetServerInfo");
    MarkNativeAsOptional("NansSurfDiscord_GetMapInfo");
    
    // Individual player data
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerRank");
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerBestTime");
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerTotalRuns");
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerName");
    MarkNativeAsOptional("NansSurfDiscord_IsPlayerOnline");
    
    // Individual map data
    MarkNativeAsOptional("NansSurfDiscord_GetMapRecord");
    MarkNativeAsOptional("NansSurfDiscord_GetMapRecordHolder");
    MarkNativeAsOptional("NansSurfDiscord_GetMapCompletions");
    MarkNativeAsOptional("NansSurfDiscord_GetMapAverageTime");
    
    // Server data
    MarkNativeAsOptional("NansSurfDiscord_GetOnlinePlayerCount");
    MarkNativeAsOptional("NansSurfDiscord_GetActivePlayerCount");
    MarkNativeAsOptional("NansSurfDiscord_GetTotalRankedPlayers");
    MarkNativeAsOptional("NansSurfDiscord_GetCurrentMap");
    
    // Leaderboard data
    MarkNativeAsOptional("NansSurfDiscord_GetTopTimes");
    MarkNativeAsOptional("NansSurfDiscord_GetRecentRecords");
    MarkNativeAsOptional("NansSurfDiscord_GetPlayerPosition");
    
    // Record announcements
    MarkNativeAsOptional("NansSurfDiscord_AnnounceRecord");
    
    // Utility functions
    MarkNativeAsOptional("NansSurfDiscord_FormatTime");
    MarkNativeAsOptional("NansSurfDiscord_GetFormattedRank");
} 