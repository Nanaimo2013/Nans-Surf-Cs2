#if defined _timer_included
 #endinput
#endif
#define _timer_included

// Timer Types
enum TimerType {
    TIMER_NONE = 0,
    TIMER_NORMAL,      // Standard timer
    TIMER_REPEAT,      // Repeating timer
    TIMER_HIGHTASK,    // High priority timer
    TIMER_MAPTIME      // Map-specific timer
}

// Timer Flags
#define TIMER_FLAG_NO_MAPCHANGE    (1<<0)    // Don't trigger on map change
#define TIMER_FLAG_STOP_ON_MAPCHANGE (1<<1)  // Stop timer on map change
#define TIMER_FLAG_REPEAT          (1<<2)    // Timer repeats
#define TIMER_FLAG_HIGHTASK        (1<<3)    // High priority timer

// Timer Functions
native Handle CreateTimer(float interval, Function func, any data = 0, int flags = 0);
native bool KillTimer(Handle timer);
native bool IsValidTimer(Handle timer);
native float GetTimerInterval(Handle timer);
native bool GetTimerRepeat(Handle timer);

// Time Formatting Functions
stock void FormatTime(float time, char[] buffer, int maxlen, bool showMilliseconds = true) {
    int minutes = RoundToFloor(time / 60.0);
    float seconds = time - float(minutes * 60);
    
    if (showMilliseconds) {
        Format(buffer, maxlen, "%02d:%06.3f", minutes, seconds);
    } else {
        Format(buffer, maxlen, "%02d:%05.2f", minutes, seconds);
    }
}

// Client Utility Functions
stock bool IsValidClient(int client, bool bAlive = false) {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    if (!IsClientInGame(client)) return false;
    if (bAlive && !IsPlayerAlive(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}

// Chat Functions
stock void CPrintToChat(int client, const char[] message, any ...) {
    char buffer[512];
    VFormat(buffer, sizeof(buffer), message, 3);
    
    // Add color tags
    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{red}", "\x02");
    ReplaceString(buffer, sizeof(buffer), "{blue}", "\x0C");
    
    PrintToChat(client, buffer);
}

// HUD Functions
stock void ShowHudText(int client, int channel, const char[] message, any ...) {
    char buffer[512];
    VFormat(buffer, sizeof(buffer), message, 4);
    
    // Set HUD parameters
    SetHudTextParams(-1.0, 0.2, 1.0, 255, 255, 255, 255);
    ShowHudText(client, channel, buffer);
} 