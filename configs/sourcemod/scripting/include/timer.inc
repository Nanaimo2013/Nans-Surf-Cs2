#if defined _timer_included
 #endinput
#endif
#define _timer_included

// Common timer-related definitions and forward declarations
enum TimerType {
    TIMER_NONE = 0,
    TIMER_NORMAL,
    TIMER_REPEAT,
    TIMER_HIGHTASK
}

// Basic timer function
native Handle CreateTimer(float interval, Function func, any data = 0, int flags = 0);
native bool KillTimer(Handle timer);

// Client utility functions
stock bool IsValidClient(int client, bool bAlive = false) {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    if (!IsClientInGame(client)) return false;
    if (bAlive && !IsPlayerAlive(client)) return false;
    return true;
}

// Placeholder for print to chat function
stock void CPrintToChat(int client, const char[] message, any ...) {
    char buffer[256];
    VFormat(buffer, sizeof(buffer), message, 3);
    PrintToChat(client, buffer);
} 