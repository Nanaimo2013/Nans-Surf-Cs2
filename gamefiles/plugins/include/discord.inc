#if defined _discord_included
    #endinput
#endif
#define _discord_included

// Dummy structures for Discord API
enum struct DiscordBot {
    char Token[256];
}

enum struct DiscordChannel {
    char Name[64];
    char ID[32];
}

enum struct DiscordUser {
    char Username[32];
    char ID[32];
}

// Dummy functions for Discord API
stock void Discord_SendMessage(const char[] webhook, const char[] message) {
    // Implementation would go here
}

stock void Discord_SendChannelMessage(const char[] token, const char[] guildId, const char[] channelId, const char[] message) {
    // Implementation would go here
}

// JSON Object (simplified)
methodmap JSON_Object < Handle {
    public native JSON_Object();
    
    public void SetString(const char[] key, const char[] value) {
        // Implementation would go here
    }
} 