#if defined _nans_surf_stats_included
    #endinput
#endif
#define _nans_surf_stats_included

/**
 * Called when a player's stats are loaded.
 *
 * @param client        Client index.
 * @param totalRuns     Total number of runs completed.
 * @param bestTime      Best time achieved (in seconds).
 * @noreturn
 */
forward void NansSurfStats_OnStatsLoaded(int client, int totalRuns, float bestTime);

/**
 * Called when a player completes a run.
 *
 * @param client        Client index.
 * @param time          Time achieved (in seconds).
 * @param isPB          Whether this was a personal best.
 * @noreturn
 */
forward void NansSurfStats_OnRunComplete(int client, float time, bool isPB);

/**
 * Gets the total number of runs completed by a player.
 *
 * @param client    Client index.
 * @return          Total runs, or -1 if invalid client.
 */
native int NansSurfStats_GetTotalRuns(int client);

/**
 * Gets the best time achieved by a player.
 *
 * @param client    Client index.
 * @return          Best time in seconds, or -1.0 if no time set.
 */
native float NansSurfStats_GetBestTime(int client);

/**
 * Gets the current rank of a player.
 *
 * @param client    Client index.
 * @return          Player rank (1-based), or 0 if unranked.
 */
native int NansSurfStats_GetRank(int client);

/**
 * Gets the total number of ranked players.
 *
 * @return          Total number of players with times.
 */
native int NansSurfStats_GetTotalRankedPlayers();

/**
 * Submits a completed run time for a player.
 *
 * @param client    Client index.
 * @param time      Time achieved in seconds.
 * @return          True if time was submitted successfully, false otherwise.
 */
native bool NansSurfStats_SubmitTime(int client, float time);

/**
 * Gets the map record holder's name.
 *
 * @param map       Map name.
 * @param buffer    Buffer to store the name.
 * @param maxlen    Maximum length of the buffer.
 * @return          True if record exists, false otherwise.
 */
native bool NansSurfStats_GetMapRecordHolder(const char[] map, char[] buffer, int maxlen);

/**
 * Gets the map record time.
 *
 * @param map       Map name.
 * @return          Record time in seconds, or -1.0 if no record exists.
 */
native float NansSurfStats_GetMapRecord(const char[] map);

/**
 * Gets the total number of completions for a map.
 *
 * @param map       Map name.
 * @return          Total number of completions.
 */
native int NansSurfStats_GetMapCompletions(const char[] map);

public SharedPlugin __pl_nans_surf_stats = {
    name = "NansSurfStats",
    file = "NansSurfStats.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_nans_surf_stats_SetNTVOptional() {
    MarkNativeAsOptional("NansSurfStats_GetTotalRuns");
    MarkNativeAsOptional("NansSurfStats_GetBestTime");
    MarkNativeAsOptional("NansSurfStats_GetRank");
    MarkNativeAsOptional("NansSurfStats_GetTotalRankedPlayers");
    MarkNativeAsOptional("NansSurfStats_SubmitTime");
    MarkNativeAsOptional("NansSurfStats_GetMapRecordHolder");
    MarkNativeAsOptional("NansSurfStats_GetMapRecord");
    MarkNativeAsOptional("NansSurfStats_GetMapCompletions");
} 