#if defined _nans_surf_timer_included
    #endinput
#endif
#define _nans_surf_timer_included

/**
 * Called when a player starts their timer.
 *
 * @param client        Client index.
 * @noreturn
 */
forward void NansSurfTimer_OnTimerStart(int client);

/**
 * Called when a player stops their timer.
 *
 * @param client        Client index.
 * @param time          Final time achieved (in seconds).
 * @param isPB          Whether this was a personal best.
 * @noreturn
 */
forward void NansSurfTimer_OnTimerStop(int client, float time, bool isPB);

/**
 * Called when a player's timer is reset.
 *
 * @param client        Client index.
 * @noreturn
 */
forward void NansSurfTimer_OnTimerReset(int client);

/**
 * Called when a player saves a checkpoint.
 *
 * @param client        Client index.
 * @param checkpoint    Checkpoint number.
 * @param time          Time at checkpoint (in seconds).
 * @noreturn
 */
forward void NansSurfTimer_OnCheckpointSaved(int client, int checkpoint, float time);

/**
 * Checks if a player's timer is running.
 *
 * @param client    Client index.
 * @return          True if timer is running, false otherwise.
 */
native bool NansSurfTimer_IsTimerRunning(int client);

/**
 * Gets a player's current time.
 *
 * @param client    Client index.
 * @return          Current time in seconds, or -1.0 if timer not running.
 */
native float NansSurfTimer_GetCurrentTime(int client);

/**
 * Gets a player's checkpoint count.
 *
 * @param client    Client index.
 * @return          Number of checkpoints saved.
 */
native int NansSurfTimer_GetCheckpointCount(int client);

/**
 * Gets a player's checkpoint time.
 *
 * @param client        Client index.
 * @param checkpoint    Checkpoint number (0-based).
 * @return             Time at checkpoint in seconds, or -1.0 if invalid.
 */
native float NansSurfTimer_GetCheckpointTime(int client, int checkpoint);

/**
 * Stops a player's timer.
 *
 * @param client    Client index.
 * @return          True if timer was stopped, false otherwise.
 */
native bool NansSurfTimer_StopTimer(int client);

/**
 * Resets a player's timer.
 *
 * @param client    Client index.
 * @return          True if timer was reset, false otherwise.
 */
native bool NansSurfTimer_ResetTimer(int client);

/**
 * Teleports a player to their last checkpoint.
 *
 * @param client    Client index.
 * @return          True if teleported successfully, false otherwise.
 */
native bool NansSurfTimer_TeleportToCheckpoint(int client);

public SharedPlugin __pl_nans_surf_timer = {
    name = "NansSurfTimer",
    file = "NansSurfTimer.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_nans_surf_timer_SetNTVOptional() {
    MarkNativeAsOptional("NansSurfTimer_IsTimerRunning");
    MarkNativeAsOptional("NansSurfTimer_GetCurrentTime");
    MarkNativeAsOptional("NansSurfTimer_GetCheckpointCount");
    MarkNativeAsOptional("NansSurfTimer_GetCheckpointTime");
    MarkNativeAsOptional("NansSurfTimer_StopTimer");
    MarkNativeAsOptional("NansSurfTimer_ResetTimer");
    MarkNativeAsOptional("NansSurfTimer_TeleportToCheckpoint");
} 