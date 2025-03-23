#if defined _nanssurf_included_
    #endinput
#endif
#define _nanssurf_included_

/**
 * Called when a player enters a start zone.
 *
 * @param client    Client index.
 */
forward void NansSurf_OnPlayerEnterStartZone(int client);

/**
 * Called when a player enters an end zone.
 *
 * @param client    Client index.
 */
forward void NansSurf_OnPlayerEnterEndZone(int client);

/**
 * Called when a player enters a checkpoint zone.
 *
 * @param client    Client index.
 * @param zone      Zone index.
 */
forward void NansSurf_OnPlayerEnterCheckpoint(int client, int zone);

/**
 * Called when a player enters a stage zone.
 *
 * @param client    Client index.
 * @param stage     Stage number.
 * @param isStart   True if entering start zone, false if end zone.
 */
forward void NansSurf_OnPlayerEnterStageZone(int client, int stage, bool isStart);

/**
 * Called when a player enters a bonus zone.
 *
 * @param client    Client index.
 * @param bonus     Bonus number.
 * @param isStart   True if entering start zone, false if end zone.
 */
forward void NansSurf_OnPlayerEnterBonusZone(int client, int bonus, bool isStart);

/**
 * Gets the spawn position for a player.
 *
 * @param position  Buffer to store position vector.
 * @param angles    Buffer to store angle vector.
 * @return          True if position was found, false otherwise.
 */
native bool NansSurf_GetSpawnPosition(float position[3], float angles[3]);

/**
 * Gets the total number of zones on the map.
 *
 * @return          Number of zones.
 */
native int NansSurf_GetZoneCount();

/**
 * Gets the position of a zone.
 *
 * @param zone      Zone index.
 * @param point1    Buffer to store first point vector.
 * @param point2    Buffer to store second point vector.
 * @return          True if zone exists, false otherwise.
 */
native bool NansSurf_GetZonePosition(int zone, float point1[3], float point2[3]);

/**
 * Checks if a player is in a start zone.
 *
 * @param client    Client index.
 * @return          True if in start zone, false otherwise.
 */
native bool NansSurf_IsInStartZone(int client);

/**
 * Checks if a player is in an end zone.
 *
 * @param client    Client index.
 * @return          True if in end zone, false otherwise.
 */
native bool NansSurf_IsInEndZone(int client);

/**
 * Gets the current stage number for a player.
 *
 * @param client    Client index.
 * @return          Current stage number, 0 if not in a stage.
 */
native int NansSurf_GetCurrentStage(int client);

/**
 * Gets the current bonus number for a player.
 *
 * @param client    Client index.
 * @return          Current bonus number, 0 if not in a bonus.
 */
native int NansSurf_GetCurrentBonus(int client);

public SharedPlugin __pl_nanssurf = {
    name = "nanssurf",
    file = "NansSurf.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_nanssurf_SetNTVOptional() {
    MarkNativeAsOptional("NansSurf_GetSpawnPosition");
    MarkNativeAsOptional("NansSurf_GetZoneCount");
    MarkNativeAsOptional("NansSurf_GetZonePosition");
    MarkNativeAsOptional("NansSurf_IsInStartZone");
    MarkNativeAsOptional("NansSurf_IsInEndZone");
    MarkNativeAsOptional("NansSurf_GetCurrentStage");
    MarkNativeAsOptional("NansSurf_GetCurrentBonus");
} 