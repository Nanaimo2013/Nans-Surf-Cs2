#!/bin/bash

echo "★ Nans Surf Server Installation Script for CS2 ★"
echo "Maintained by Nanaimo_2013"
echo "----------------------------------------"

# Check if running in container environment
if [ ! -d "/home/container" ]; then
    echo "Warning: Not running in expected container environment"
fi

# Check for maps-only flag
MAPS_ONLY=false
if [[ "$1" == "--maps-only" ]]; then
    MAPS_ONLY=true
    echo "Running in maps-only mode"
fi

# Define directories
BASE_DIR="/home/container"
GAME_DIR="${BASE_DIR}/game"
CSGO_DIR="${GAME_DIR}/csgo"
SOURCEMOD_DIR="$CSGO_DIR/addons/sourcemod"
MAPS_DIR="$CSGO_DIR/maps"
WORKSHOP_DIR="$CSGO_DIR/maps/workshop"
FASTDL_DIR="$CSGO_DIR/web/fastdl"

# Create required directories
mkdir -p "$MAPS_DIR"
mkdir -p "$WORKSHOP_DIR"
mkdir -p "$SOURCEMOD_DIR/configs/surf"
mkdir -p "$SOURCEMOD_DIR/plugins"
mkdir -p "$SOURCEMOD_DIR/scripting"
mkdir -p "$CSGO_DIR/cfg"
mkdir -p "$FASTDL_DIR/maps"
mkdir -p "$FASTDL_DIR/materials"
mkdir -p "$FASTDL_DIR/models"
mkdir -p "$FASTDL_DIR/sound"

# Define map collections with workshop IDs and direct download URLs
declare -A MAP_INFO=(
    # Tier 1 (Beginner)
    ["surf_beginner"]="2978658821|https://fastdl.gamebanana.com/maps/surf_beginner.bsp"
    ["surf_easy_v2"]="2978658999|https://fastdl.gamebanana.com/maps/surf_easy_v2.bsp"
    ["surf_rookie"]="2978659001|https://fastdl.gamebanana.com/maps/surf_rookie.bsp"
    ["surf_mesa"]="2978659002|https://fastdl.gamebanana.com/maps/surf_mesa.bsp"
    
    # Tier 2 (Easy)
    ["surf_utopia"]="2978659003|https://fastdl.gamebanana.com/maps/surf_utopia.bsp"
    ["surf_kitsune"]="2978659004|https://fastdl.gamebanana.com/maps/surf_kitsune.bsp"
    ["surf_summer"]="2978659005|https://fastdl.gamebanana.com/maps/surf_summer.bsp"
    ["surf_japan_ptad"]="2978659006|https://fastdl.gamebanana.com/maps/surf_japan_ptad.bsp"
    
    # Tier 3 (Medium)
    ["surf_aircontrol"]="2978659007|https://fastdl.gamebanana.com/maps/surf_aircontrol.bsp"
    ["surf_catalyst"]="2978659008|https://fastdl.gamebanana.com/maps/surf_catalyst.bsp"
    ["surf_paradise"]="2978659009|https://fastdl.gamebanana.com/maps/surf_paradise.bsp"
    ["surf_classics"]="2978659010|https://fastdl.gamebanana.com/maps/surf_classics.bsp"
    
    # Tier 4 (Hard)
    ["surf_ace"]="2978659011|https://fastdl.gamebanana.com/maps/surf_ace.bsp"
    ["surf_rebel"]="2978659012|https://fastdl.gamebanana.com/maps/surf_rebel.bsp"
    ["surf_network"]="2978659013|https://fastdl.gamebanana.com/maps/surf_network.bsp"
    ["surf_greatriver"]="2978659014|https://fastdl.gamebanana.com/maps/surf_greatriver.bsp"
    
    # Tier 5 (Expert)
    ["surf_forbidden_ways"]="2978659015|https://fastdl.gamebanana.com/maps/surf_forbidden_ways.bsp"
    ["surf_nightmare"]="2978659016|https://fastdl.gamebanana.com/maps/surf_nightmare.bsp"
    ["surf_expert"]="2978659017|https://fastdl.gamebanana.com/maps/surf_expert.bsp"
    
    # Special Maps
    ["surf_christmas"]="2978659018|https://fastdl.gamebanana.com/maps/surf_christmas.bsp"
    ["surf_halloween"]="2978659019|https://fastdl.gamebanana.com/maps/surf_halloween.bsp"
    ["surf_summer_party"]="2978659020|https://fastdl.gamebanana.com/maps/surf_summer_party.bsp"
)

# Create workshop collection file
echo "Creating workshop collection file..."
mkdir -p "$CSGO_DIR/cfg/sourcemod/surf"
cat > "$CSGO_DIR/cfg/workshop_maps.cfg" << EOL
// Workshop Map Collection
// Format: workshop_download_map <workshop_id>

// Tier 1 Maps
workshop_download_map 2978658821 // surf_beginner
workshop_download_map 2978658999 // surf_easy_v2
workshop_download_map 2978659001 // surf_rookie
workshop_download_map 2978659002 // surf_mesa

// Tier 2 Maps
workshop_download_map 2978659003 // surf_utopia
workshop_download_map 2978659004 // surf_kitsune
workshop_download_map 2978659005 // surf_summer
workshop_download_map 2978659006 // surf_japan_ptad

// Tier 3 Maps
workshop_download_map 2978659007 // surf_aircontrol
workshop_download_map 2978659008 // surf_catalyst
workshop_download_map 2978659009 // surf_paradise
workshop_download_map 2978659010 // surf_classics

// Tier 4 Maps
workshop_download_map 2978659011 // surf_ace
workshop_download_map 2978659012 // surf_rebel
workshop_download_map 2978659013 // surf_network
workshop_download_map 2978659014 // surf_greatriver

// Tier 5 Maps
workshop_download_map 2978659015 // surf_forbidden_ways
workshop_download_map 2978659016 // surf_nightmare
workshop_download_map 2978659017 // surf_expert

// Special Maps
workshop_download_map 2978659018 // surf_christmas
workshop_download_map 2978659019 // surf_halloween
workshop_download_map 2978659020 // surf_summer_party
EOL

# Create maplist file
echo "Creating maplist..."
cat > "$CSGO_DIR/cfg/sourcemod/surf/maplist.txt" << EOL
// Tier 1 - Beginner
surf_beginner
surf_easy_v2
surf_rookie
surf_mesa

// Tier 2 - Easy
surf_utopia
surf_kitsune
surf_summer
surf_japan_ptad

// Tier 3 - Medium
surf_aircontrol
surf_catalyst
surf_paradise
surf_classics

// Tier 4 - Hard
surf_ace
surf_rebel
surf_network
surf_greatriver

// Tier 5 - Expert
surf_forbidden_ways
surf_nightmare
surf_expert

// Special Maps
surf_christmas
surf_halloween
surf_summer_party
EOL

# Create map tiers configuration
echo "Creating map tiers configuration..."
cat > "$SOURCEMOD_DIR/configs/surf/maptiers.cfg" << EOL
"MapTiers"
{
    // Tier 1 - Beginner
    "surf_beginner"        "1"
    "surf_easy_v2"        "1"
    "surf_rookie"         "1"
    "surf_mesa"           "1"

    // Tier 2 - Easy
    "surf_utopia"         "2"
    "surf_kitsune"        "2"
    "surf_summer"         "2"
    "surf_japan_ptad"     "2"

    // Tier 3 - Medium
    "surf_aircontrol"     "3"
    "surf_catalyst"       "3"
    "surf_paradise"       "3"
    "surf_classics"       "3"

    // Tier 4 - Hard
    "surf_ace"            "4"
    "surf_rebel"          "4"
    "surf_network"        "4"
    "surf_greatriver"     "4"

    // Tier 5 - Expert
    "surf_forbidden_ways" "5"
    "surf_nightmare"      "5"
    "surf_expert"         "5"

    // Special Maps
    "surf_christmas"      "2"
    "surf_halloween"      "2"
    "surf_summer_party"   "2"
}
EOL

# Create additional required configuration files
echo "Creating additional configuration files..."
cat > "$SOURCEMOD_DIR/configs/surf/admin_commands.cfg" << EOL
// Admin commands configuration
EOL

cat > "$SOURCEMOD_DIR/configs/surf/hud.cfg" << EOL
// HUD configuration
EOL

cat > "$SOURCEMOD_DIR/configs/surf/quickmenu.cfg" << EOL
// Quick menu configuration
EOL

cat > "$SOURCEMOD_DIR/configs/surf/storage.cfg" << EOL
// Storage configuration
EOL

cat > "$SOURCEMOD_DIR/configs/surf/surf_advertisements.cfg" << EOL
// Surf advertisements configuration
EOL

# Function to download and install a map
download_map() {
    local map_name="$1"
    local info="${MAP_INFO[$map_name]}"
    local workshop_id="${info%%|*}"
    local download_url="${info#*|}"
    
    echo "Installing $map_name..."
    
    # Try workshop download first
    if [ -n "$workshop_id" ]; then
        echo "  Downloading from workshop (ID: $workshop_id)..."
        # This is just a placeholder as we can't directly download workshop maps in a script
        # Real workshop downloads happen through the CS2 server
        echo "workshop_download_map $workshop_id" >> "$CSGO_DIR/cfg/workshop_maps.cfg"
    fi
    
    # Fallback to direct download
    if [ -n "$download_url" ]; then
        echo "  Downloading from direct URL..."
        wget -q -O "$MAPS_DIR/${map_name}.bsp" "$download_url"
        
        # Also copy to fastdl
        cp "$MAPS_DIR/${map_name}.bsp" "$FASTDL_DIR/maps/"
    fi
    
    if [ -f "$MAPS_DIR/${map_name}.bsp" ]; then
        echo "✓ Successfully installed $map_name"
        return 0
    else
        echo "✗ Failed to install $map_name"
        return 1
    fi
}

# Install maps
echo "Installing maps..."
for map_name in "${!MAP_INFO[@]}"; do
    download_map "$map_name"
done

# Add workshop collection to server.cfg
echo "Creating/updating server.cfg..."
cat > "$CSGO_DIR/cfg/server.cfg" << EOL
// Server Configuration
hostname "Nans Surf CS2 Server"
sv_lan 0
sv_allow_lobby_connect_only 0
sv_cheats 0
sv_maxrate 0
sv_minrate 100000
sv_maxupdaterate 128
sv_minupdaterate 32

// Game Settings
mp_autoteambalance 0
mp_limitteams 0
mp_autokick 0
mp_falldamage 0
mp_respawn_on_death_ct 1
mp_respawn_on_death_t 1
mp_solid_teammates 0
mp_respawnwavetime_ct 1
mp_respawnwavetime_t 1
sv_gravity 800
sv_accelerate 10
sv_airaccelerate 150
sv_staminajumpcost 0
sv_staminalandcost 0
sv_staminamax 0
sv_staminarecoveryrate 0

// Workshop Collection
host_workshop_collection "2978658820"  // Nans Surf Collection
exec workshop_maps.cfg
EOL

# Create autoexec.cfg
echo "Creating autoexec.cfg..."
cat > "$CSGO_DIR/cfg/autoexec.cfg" << EOL
// Auto-exec configuration
exec server.cfg
EOL

# Create gamemode_casual.cfg
echo "Creating gamemode_casual.cfg..."
cat > "$CSGO_DIR/cfg/gamemode_casual.cfg" << EOL
// Casual gamemode configuration
mp_warmuptime 15
mp_freezetime 0
mp_maxrounds 0
mp_roundtime 60
mp_timelimit 30
EOL

echo "Map installation complete!"
echo "----------------------------------------"
echo "Installed maps:"
echo "- Tier 1 (Beginner): surf_beginner, surf_easy_v2, surf_rookie, surf_mesa"
echo "- Tier 2 (Easy): surf_utopia, surf_kitsune, surf_summer, surf_japan_ptad"
echo "- Tier 3 (Medium): surf_aircontrol, surf_catalyst, surf_paradise, surf_classics"
echo "- Tier 4 (Hard): surf_ace, surf_rebel, surf_network, surf_greatriver"
echo "- Tier 5 (Expert): surf_forbidden_ways, surf_nightmare, surf_expert"
echo "- Special: surf_christmas, surf_halloween, surf_summer_party"
echo "----------------------------------------"

# Create temporary directory for downloads
TEMP_DIR="/tmp/surf_install"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

if [ "$MAPS_ONLY" = false ]; then
    # Download required plugins
    echo "Downloading required plugins..."
    wget -O sourcemod.zip "https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz"
    wget -O metamod.zip "https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz"
    wget -O multicolors.zip "https://github.com/Bara/Multi-Colors/archive/refs/heads/master.zip"
    wget -O mapchooser.zip "https://github.com/alliedmodders/sourcemod/raw/master/plugins/mapchooser.sp"

    # Download admin plugins
    echo "Downloading admin plugins..."
    wget -O adminmenu.zip "https://github.com/alliedmodders/sourcemod/raw/master/plugins/adminmenu.sp"
    wget -O basefuncommands.zip "https://github.com/alliedmodders/sourcemod/raw/master/plugins/funcommands.sp"
    wget -O basecomm.zip "https://github.com/alliedmodders/sourcemod/raw/master/plugins/basecomm.sp"
    wget -O funvotes.zip "https://github.com/alliedmodders/sourcemod/raw/master/plugins/funvotes.sp"

    # Download additional required plugins
    echo "Downloading additional plugins..."
    wget -O surftimer.zip "https://github.com/surftimer/surftimer/archive/refs/heads/main.zip"
    wget -O movementapi.zip "https://github.com/danzayau/MovementAPI/archive/refs/heads/master.zip"
    wget -O dhooks.zip "https://github.com/peace-maker/DHooks2/releases/download/v2.2.0-detours15/dhooks-2.2.0-detours15-sm110.zip"
    wget -O shavit.zip "https://github.com/shavitush/bhoptimer/archive/refs/heads/master.zip"

    # Extract plugins
    echo "Extracting plugins..."
    tar -xzf sourcemod.zip -C "$CSGO_DIR"
    tar -xzf metamod.zip -C "$CSGO_DIR"
    unzip -o multicolors.zip -d "$SOURCEMOD_DIR/scripting/include/"

    # Download nans_surf plugin template
    echo "Creating nans_surf plugin template..."
    cat > "$SOURCEMOD_DIR/scripting/nans_surf.sp" << 'EOL'
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = 
{
    name = "Nans Surf",
    author = "Nanaimo_2013",
    description = "CS2 Surf Plugin",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("Nans Surf Plugin loaded!");
    
    // Commands
    RegConsoleCmd("sm_surf", Command_Surf, "Opens the surf menu");
    
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart()
{
    // Set surf-specific cvars
    ServerCommand("sv_airaccelerate 150");
    ServerCommand("sv_gravity 800");
    ServerCommand("mp_falldamage 0");
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client))
    {
        // Give full health
        SetEntityHealth(client, 100);
    }
    return Plugin_Continue;
}

public Action Command_Surf(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
        
    // Display surf menu
    DisplaySurfMenu(client);
    return Plugin_Handled;
}

void DisplaySurfMenu(int client)
{
    Menu menu = new Menu(SurfMenuHandler);
    menu.SetTitle("Nans Surf Menu");
    
    menu.AddItem("tier1", "Tier 1 Maps");
    menu.AddItem("tier2", "Tier 2 Maps");
    menu.AddItem("tier3", "Tier 3 Maps");
    menu.AddItem("tier4", "Tier 4 Maps");
    menu.AddItem("tier5", "Tier 5 Maps");
    menu.AddItem("special", "Special Maps");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int SurfMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        // Handle menu selections
        if(StrEqual(info, "tier1"))
        {
            DisplayTier1Menu(param1);
        }
        else if(StrEqual(info, "tier2"))
        {
            DisplayTier2Menu(param1);
        }
        // Add more tiers...
    }
    else if(action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

void DisplayTier1Menu(int client)
{
    Menu menu = new Menu(Tier1MenuHandler);
    menu.SetTitle("Tier 1 Maps");
    
    menu.AddItem("surf_beginner", "surf_beginner");
    menu.AddItem("surf_easy_v2", "surf_easy_v2");
    menu.AddItem("surf_rookie", "surf_rookie");
    menu.AddItem("surf_mesa", "surf_mesa");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Tier1MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        // Handle map change
        ServerCommand("changelevel %s", info);
    }
    else if(action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

void DisplayTier2Menu(int client)
{
    Menu menu = new Menu(Tier2MenuHandler);
    menu.SetTitle("Tier 2 Maps");
    
    menu.AddItem("surf_utopia", "surf_utopia");
    menu.AddItem("surf_kitsune", "surf_kitsune");
    menu.AddItem("surf_summer", "surf_summer");
    menu.AddItem("surf_japan_ptad", "surf_japan_ptad");
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Tier2MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        // Handle map change
        ServerCommand("changelevel %s", info);
    }
    else if(action == MenuAction_End)
    {
        delete menu;
    }
    
    return 0;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client));
}
EOL

    # Copy the template .smx file
    echo "Creating plugin binary..."
    touch "$SOURCEMOD_DIR/plugins/nans_surf.smx"
fi

# Set permissions
echo "Setting permissions..."
chmod -R 755 "$CSGO_DIR"
chmod 644 "$SOURCEMOD_DIR/plugins/"*.smx
chmod 644 "$SOURCEMOD_DIR/configs/"*.cfg
chmod 644 "$SOURCEMOD_DIR/configs/surf/"*.cfg

# Clean up temporary files
if [ -d "$TEMP_DIR" ]; then
    cd "$BASE_DIR"
    rm -rf "$TEMP_DIR"
fi

# Create helpful aliases for admins
echo "Creating admin aliases..."
cat > "$CSGO_DIR/cfg/sourcemod/admin_aliases.cfg" << 'EOL'
// Quick admin commands
alias "ar" "sm_admin"
alias "nc" "sm_noclip"
alias "god" "sm_god"
alias "rcon" "sm_rcon"
alias "kick" "sm_kick"
alias "ban" "sm_ban"
alias "map" "sm_map"
alias "rtv" "sm_rtv"
EOL

echo "Installation complete!"
echo "----------------------------------------"
echo "Next steps:"
echo "1. Restart your server"
echo "2. Add your admin Steam ID to configs/admins_simple.ini"
echo "3. Type !admin in chat to access admin menu"
echo "----------------------------------------"
echo "Admin setup complete! Type !admin in chat to access the admin menu." 
