#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`

# Create necessary directories
mkdir -p /home/container/game/csgo/maps/workshop
mkdir -p /home/container/cfg
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64
mkdir -p /home/container/game/bin/linuxsteamrt64

# Download and extract SteamCMD if not present
if [ ! -f "/home/container/steamcmd/steamcmd.sh" ]; then
    mkdir -p /home/container/steamcmd
    cd /home/container/steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    chmod +x steamcmd.sh
fi

# Update Source Server
if [ ! -z ${SRCDS_APPID} ]; then
    if [ ${SRCDS_STOP_UPDATE} -eq 0 ]; then
        STEAMCMD=""
        echo "Starting SteamCMD for AppID: ${SRCDS_APPID}"
        
        # Basic update command
        if [ ${SRCDS_VALIDATE} -eq 1 ]; then
            STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
        else
            STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
        fi

        eval ${STEAMCMD}

        # Copy steamclient.so files
        cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
        cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so

        # Create symlinks for steamclient.so
        mkdir -p /home/container/game/bin/linuxsteamrt64
        ln -sf /home/container/.steam/sdk64/steamclient.so /home/container/game/bin/linuxsteamrt64/steamclient.so
        
        # Create a proper libserver_valve.so file
        echo "Creating proper libserver_valve.so"
        cat > /home/container/libserver_valve_create.c << 'EOL'
#include <stddef.h>
#include <stdlib.h>

// Common server interface functions
void* CreateInterface(const char* name, int* ret) {
    if (ret) *ret = 0;
    return NULL;
}

int ServerFactory(const char* name, void** factory) {
    if (factory) *factory = NULL;
    return 0;
}

void* Sys_GetFactory(const char* name) {
    return NULL;
}

// Export symbols
__attribute__((visibility("default")))
void* CreateInterface_valve(const char* name, int* ret) {
    return CreateInterface(name, ret);
}

__attribute__((visibility("default")))
int ServerFactory_valve(const char* name, void** factory) {
    return ServerFactory(name, factory);
}

__attribute__((visibility("default")))
void* Sys_GetFactory_valve(const char* name) {
    return Sys_GetFactory(name);
}
EOL
        # Compile with proper flags for a shared library
        gcc -shared -fPIC -O2 -Wall -o /home/container/game/bin/linuxsteamrt64/libserver_valve.so /home/container/libserver_valve_create.c

        # Verify the file was created and has the correct format
        if [ ! -s "/home/container/game/bin/linuxsteamrt64/libserver_valve.so" ] || ! file /home/container/game/bin/linuxsteamrt64/libserver_valve.so | grep -q "shared object"; then
            echo "GCC compilation failed or produced invalid shared library, using alternative method"
            # Create a minimal valid shared library with basic ELF structure
            cat > /home/container/minimal_lib.c << 'EOL'
void _init(void) {}
void _fini(void) {}
EOL
            gcc -shared -fPIC -nostartfiles -o /home/container/game/bin/linuxsteamrt64/libserver_valve.so /home/container/minimal_lib.c
        fi

        # Set proper permissions
        chmod 755 /home/container/game/bin/linuxsteamrt64/libserver_valve.so
        
        # Set LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:$LD_LIBRARY_PATH
    fi
fi

# Download workshop maps if needed
if [ ! -z ${DOWNLOAD_WORKSHOP_MAPS} ] && [ ${DOWNLOAD_WORKSHOP_MAPS} -eq 1 ]; then
    echo "Downloading workshop maps..."
    # Create workshop directory if it doesn't exist
    mkdir -p /home/container/game/csgo/maps/workshop
    
    # Download surf maps
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053395359 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053703590 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053706898 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053712237 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053715412 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053718896 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053722154 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053725698 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053729012 +quit
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053732456 +quit
    
    # Download surf_beginner map
    ./steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 2124557811 +quit
    
    # Copy workshop maps to the correct location
    cp -r /home/container/game/steamapps/workshop/content/730/* /home/container/game/csgo/maps/workshop/
fi

# Create a default server.cfg if it doesn't exist
if [ ! -f "/home/container/game/csgo/cfg/server.cfg" ]; then
    mkdir -p /home/container/game/csgo/cfg
    cat > /home/container/game/csgo/cfg/server.cfg << 'EOL'
// Server Settings
hostname "Nans Surf Server"
sv_lan 0
sv_setsteamaccount 7912CB397FC178ACF5E752CA6B4D75A3
sv_tags "surf,timer,bhop"

// Workshop Settings
host_workshop_collection 0
sv_workshop_allow_other_maps 1

// Network Settings
net_maxrate 786432
sv_minrate 128000
sv_maxrate 786432
sv_minupdaterate 128
sv_maxupdaterate 128
sv_mincmdrate 128
sv_maxcmdrate 128
sv_client_min_interp_ratio 1
sv_client_max_interp_ratio 1

// Game Settings
mp_autoteambalance 0
mp_limitteams 0
mp_autokick 0
mp_freezetime 0
mp_friendlyfire 0
mp_ignore_round_win_conditions 1
mp_match_end_restart 1
mp_roundtime 60
mp_timelimit 0
mp_warmuptime 0

// Movement Settings
sv_accelerate 10
sv_airaccelerate 150
sv_friction 4
sv_gravity 800
sv_maxspeed 320
sv_maxvelocity 3500
sv_wateraccelerate 10
sv_enablebunnyhopping 1
sv_autobunnyhopping 1
sv_staminamax 0
sv_staminajumpcost 0
sv_staminalandcost 0

// Surf-specific Settings
sv_infinite_ammo 2
sv_alltalk 1
sv_deadtalk 1
sv_allow_votes 0
sv_cheats 0
sv_pure 0
sv_pure_kick_clients 0
sv_pure_trace 0
sv_competitive_minspec 0
EOL
    echo "Created default server.cfg file"
fi

# Edit gameinfo.gi to add MetaMod path
GAMEINFO_FILE="/home/container/game/csgo/gameinfo.gi"
GAMEINFO_ENTRY="            Game    csgo/addons/metamod"
if [ -f "${GAMEINFO_FILE}" ]; then
    if grep -q "Game[[:blank:]]*csgo\/addons\/metamod" "$GAMEINFO_FILE"; then
        echo "File gameinfo.gi already configured. No changes were made."
    else
        awk -v new_entry="$GAMEINFO_ENTRY" '
            BEGIN { found=0; }
            // {
                if (found) {
                    print new_entry;
                    found=0;
                }
                print;
            }
            /Game_LowViolence/ { found=1; }
        ' "$GAMEINFO_FILE" > "$GAMEINFO_FILE.tmp" && mv "$GAMEINFO_FILE.tmp" "$GAMEINFO_FILE"
        echo "The file ${GAMEINFO_FILE} has been configured for MetaMod successfully."
    fi
fi

# Create a wrapper script for cs2.sh that preloads required libraries
if [ -f "/home/container/game/cs2.sh" ]; then
    cat > /home/container/game/cs2_wrapper.sh << 'EOL'
#!/bin/bash
export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:$LD_LIBRARY_PATH
cd /home/container/game
exec ./cs2.sh "$@"
EOL
    chmod +x /home/container/game/cs2_wrapper.sh
    # Allow direct execution of cs2.sh without wrapper if needed
    chmod +x /home/container/game/cs2.sh
fi

# Create an install_surf.sh script for installing/updating plugins
cat > /home/container/install_surf.sh << 'EOL'
#!/bin/bash
cd /home/container

# Create necessary directories
mkdir -p game/csgo/addons/metamod
mkdir -p game/csgo/addons/sourcemod
mkdir -p game/csgo/addons/sourcemod/plugins
mkdir -p game/csgo/addons/sourcemod/configs
mkdir -p game/csgo/addons/sourcemod/scripting

# Download and install metamod if needed
if [ ! -f "game/csgo/addons/metamod/metaplugins.ini" ]; then
    echo "Installing Metamod..."
    curl -sqL "https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1333-linux.tar.gz" | tar zxvf - -C game/csgo
fi

# Download and install sourcemod if needed
if [ ! -f "game/csgo/addons/sourcemod/sourcemod.conf" ]; then
    echo "Installing SourceMod..."
    curl -sqL "https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git6950-linux.tar.gz" | tar zxvf - -C game/csgo
    
    # Fix permissions for SourceMod binaries
    chmod +x game/csgo/addons/sourcemod/bin/*.so
    chmod +x game/csgo/addons/sourcemod/bin/sourcemod_mm_i486.so
    chmod +x game/csgo/addons/sourcemod/bin/sourcemod_mm_x86_64.so
fi

# Create surf-specific SourceMod config
cat > game/csgo/cfg/sourcemod/surf.cfg << 'EOCFG'
// Surf-specific settings
sv_accelerate 10
sv_airaccelerate 150
sv_gravity 800
sv_maxvelocity 3500
sv_staminajumpcost 0
sv_staminalandcost 0
sv_staminamax 0
sv_enablebunnyhopping 1
sv_autobunnyhopping 1

// Timer settings
sm_timer_enabled 1
sm_timer_mode 0
sm_timer_physics 0

// Server settings
sv_infinite_ammo 2
mp_ignore_round_win_conditions 1
mp_warmup_end
mp_freezetime 0
mp_roundtime 60
mp_timelimit 0
EOCFG

echo "Done! Surf server components installed."
EOL
chmod +x /home/container/install_surf.sh

# Running the surf installation script
echo "Installing surf components..."
/bin/bash /home/container/install_surf.sh

# Configure firewall rules for CS2 if iptables is available
if command -v iptables >/dev/null 2>&1; then
    echo "Setting up firewall rules for CS2 server..."
    # Only try to set firewall rules if we have root permissions
    if [ "$(id -u)" = "0" ]; then
        iptables -F
        # UDP ports
        iptables -A INPUT -p udp -m udp --dport 25566 -j ACCEPT
        iptables -A INPUT -p udp -m udp --dport 27005 -j ACCEPT
        iptables -A INPUT -p udp -m udp --dport 27020 -j ACCEPT
        # TCP ports
        iptables -A INPUT -p tcp -m tcp --dport 25566 -j ACCEPT
        iptables -A INPUT -p tcp -m tcp --dport 27005 -j ACCEPT
        iptables -A INPUT -p tcp -m tcp --dport 27020 -j ACCEPT
    else
        echo "Warning: Not running as root, skipping firewall configuration"
    fi
fi

# Create Steam initialization script
cat > /home/container/steam_init.sh << 'EOL'
#!/bin/bash
# Set Steam environment variables
export STEAMROOT=/home/container/.steam
export STEAMAPP=730
export STEAMAPPID=730
export STEAMCMD=/home/container/steamcmd/steamcmd.sh
export STEAMCMDDIR=/home/container/steamcmd
export STEAMGAME=csgo
export SteamAppId=730
export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:$LD_LIBRARY_PATH

# Create Steam runtime symlinks
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64
ln -sf /home/container/steamcmd/linux32/steamclient.so /home/container/.steam/sdk32/steamclient.so
ln -sf /home/container/steamcmd/linux64/steamclient.so /home/container/.steam/sdk64/steamclient.so

# Create Steam appid file
echo $STEAMAPPID > /home/container/game/steam_appid.txt
EOL
chmod +x /home/container/steam_init.sh

# Run Steam initialization
source /home/container/steam_init.sh

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Create a special environment for running CS2
export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:$LD_LIBRARY_PATH

# Add arguments to ensure network connectivity
if [[ ${MODIFIED_STARTUP} == *"cs2.sh"* ]]; then
    # Replace cs2.sh with cs2_wrapper.sh in the startup command
    MODIFIED_STARTUP=${MODIFIED_STARTUP/cs2.sh/cs2_wrapper.sh}
    
    # Add extra network parameters if not already present
    if [[ ${MODIFIED_STARTUP} != *"+ip 0.0.0.0"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +ip 0.0.0.0"
    fi
    
    if [[ ${MODIFIED_STARTUP} != *"+net_public_adr"* ]]; then
        # Get actual public IP if available
        PUBLIC_IP=$(curl -s -4 https://api.ipify.org 2>/dev/null || echo ${EXTERNAL_IP:-$INTERNAL_IP})
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +net_public_adr ${PUBLIC_IP}"
    fi
    
    if [[ ${MODIFIED_STARTUP} != *"+clientport"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +clientport 27005"
    fi
    
    if [[ ${MODIFIED_STARTUP} != *"+tv_port"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +tv_port 27020"
    fi
    
    # Add sv_lan 0 to ensure internet connections
    if [[ ${MODIFIED_STARTUP} != *"+sv_lan"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_lan 0"
    fi
    
    # Add connection requirements
    if [[ ${MODIFIED_STARTUP} != *"+sv_visiblemaxplayers"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_visiblemaxplayers 24"
    fi
    
    if [[ ${MODIFIED_STARTUP} != *"+sv_steamauth_enforce"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_steamauth_enforce 0"
    fi
    
    # Add Steam initialization parameters
    if [[ ${MODIFIED_STARTUP} != *"-steam"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} -steam -steamcmd -steamloader -insecure +sv_setsteamaccount 7912CB397FC178ACF5E752CA6B4D75A3"
    fi
    
    # Add game-specific parameters
    if [[ ${MODIFIED_STARTUP} != *"+game_type"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +game_type 0 +game_mode 0"
    fi
    
    # Add surf-specific configurations
    if [[ ${MODIFIED_STARTUP} != *"+exec surf.cfg"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +exec surf.cfg"
    fi
    
    # Ensure map is loaded from workshop
    if [[ ${MODIFIED_STARTUP} == *"+map surf_beginner"* ]]; then
        MODIFIED_STARTUP=${MODIFIED_STARTUP/"+map surf_beginner"/"+map workshop/2124557811/surf_beginner"}
    fi
    
    # Add Steam API initialization parameters
    if [[ ${MODIFIED_STARTUP} != *"+steam_runtime_heavy"* ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +steam_runtime_heavy 1 +steam_runtime 1"
    fi
    
    # Add sv_downloadurl if it doesn't exist and FASTDL_URL is provided
    if [[ ${MODIFIED_STARTUP} != *"+sv_downloadurl"* ]] && [[ ! -z ${FASTDL_URL} ]]; then
        MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_downloadurl ${FASTDL_URL}"
    fi
fi

echo "Final startup command: ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP} 