#!/bin/bash
cd /home/container

# Output current environment
echo "Running on Debian $(cat /etc/debian_version)"
echo "Current timezone: $(cat /etc/timezone)"
echo "Current working directory: $(pwd)"

# Make internal Docker IP address available to processes
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`
echo "Internal IP: ${INTERNAL_IP}"

# Create necessary directories
mkdir -p /home/container/game/csgo/maps/workshop
mkdir -p /home/container/cfg
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64
mkdir -p /home/container/game/bin/linuxsteamrt64
mkdir -p /home/container/game/csgo/addons/metamod/bin
mkdir -p /home/container/game/csgo/addons/sourcemod/bin

# Download and extract SteamCMD
if [ ! -f "/home/container/steamcmd/steamcmd.sh" ]; then
    echo "Installing SteamCMD..."
    mkdir -p /home/container/steamcmd
    cd /home/container/steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    chmod +x steamcmd.sh
fi

# Set up Steam environment
echo "Setting up Steam environment..."
export STEAMROOT=/home/container/.steam
export STEAMAPP=730
export STEAMAPPID=730
export STEAMCMD=/home/container/steamcmd/steamcmd.sh
export STEAMCMDDIR=/home/container/steamcmd
export STEAMGAME=csgo
export SteamAppId=730
export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:$LD_LIBRARY_PATH

# Create Steam runtime symlinks
ln -sf /home/container/steamcmd/linux32/steamclient.so /home/container/.steam/sdk32/steamclient.so
ln -sf /home/container/steamcmd/linux64/steamclient.so /home/container/.steam/sdk64/steamclient.so

# Create Steam appid file
echo $STEAMAPPID > /home/container/game/steam_appid.txt

# Update CS2 Server
if [ ! -z ${SRCDS_APPID} ]; then
    echo "Updating CS2 Server..."
    STEAMCMD_ARGS="+force_install_dir /home/container +login anonymous +app_update ${SRCDS_APPID}"
    if [ ${SRCDS_VALIDATE:-0} -eq 1 ]; then
        STEAMCMD_ARGS="${STEAMCMD_ARGS} validate"
    fi
    ${STEAMCMD} ${STEAMCMD_ARGS} +quit
fi

# Install MetaMod and SourceMod
echo "Installing MetaMod and SourceMod..."
cd /home/container/game/csgo

# Install MetaMod
if [ ! -f "addons/metamod/sourcemod.vdf" ]; then
    echo "Installing MetaMod..."
    curl -sqL "https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1333-linux.tar.gz" | tar xzf -
fi

# Install SourceMod
if [ ! -f "addons/sourcemod/sourcemod.vdf" ]; then
    echo "Installing SourceMod..."
    curl -sqL "https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git6950-linux.tar.gz" | tar xzf -
fi

# Fix permissions
chmod -R 755 addons/metamod
chmod -R 755 addons/sourcemod

# Create proper libserver_valve.so
echo "Creating libserver_valve.so..."
cat > /home/container/libserver_valve_create.c << 'EOL'
#include <stddef.h>
#include <stdlib.h>

__attribute__((visibility("default")))
void* CreateInterface_valve(const char* name, int* ret) {
    if (ret) *ret = 0;
    return NULL;
}

__attribute__((visibility("default")))
int ServerFactory_valve(const char* name, void** factory) {
    if (factory) *factory = NULL;
    return 0;
}

__attribute__((visibility("default")))
void* Sys_GetFactory_valve(const char* name) {
    return NULL;
}
EOL

gcc -shared -fPIC -O2 -Wall -o /home/container/game/bin/linuxsteamrt64/libserver_valve.so /home/container/libserver_valve_create.c
chmod 755 /home/container/game/bin/linuxsteamrt64/libserver_valve.so

# Download workshop maps if enabled
if [ ${DOWNLOAD_WORKSHOP_MAPS:-0} -eq 1 ]; then
    echo "Downloading workshop maps..."
    ${STEAMCMD} +login anonymous +workshop_download_item 730 2124557811 validate +quit
    
    if [ -d "/home/container/game/steamapps/workshop/content/730" ]; then
        cp -rf /home/container/game/steamapps/workshop/content/730/* /home/container/game/csgo/maps/workshop/
        chmod -R 755 /home/container/game/csgo/maps/workshop/
    fi
fi

# Create default server.cfg if it doesn't exist
if [ ! -f "/home/container/game/csgo/cfg/server.cfg" ]; then
    echo "Creating server.cfg..."
    cat > /home/container/game/csgo/cfg/server.cfg << 'EOL'
// Server Settings
hostname "Nans Surf Server"
sv_lan 0
sv_tags "surf,timer,bhop"

// Workshop Settings
host_workshop_collection 2124557811
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
fi

# Create surf.cfg for SourceMod
echo "Creating surf.cfg for SourceMod..."
cat > /home/container/game/csgo/cfg/sourcemod/surf.cfg << 'EOL'
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
EOL

# Create MetaMod config
echo "Creating MetaMod config..."
cat > /home/container/game/csgo/addons/metamod.vdf << 'EOL'
"Plugin"
{
    "file"    "../csgo/addons/metamod/sourcemod.vdf"
}
EOL

# Create SourceMod config
echo "Creating SourceMod config..."
cat > /home/container/game/csgo/addons/sourcemod.vdf << 'EOL'
"Plugin"
{
    "file"    "addons/sourcemod/bin/sourcemod_mm"
}
EOL

# Create cs2_wrapper.sh
echo "Creating CS2 wrapper script..."
cat > /home/container/game/cs2_wrapper.sh << 'EOL'
#!/bin/bash
export LD_LIBRARY_PATH=/home/container/game/bin/linuxsteamrt64:/home/container/.steam/sdk64:/home/container/game/csgo/addons/metamod/bin:/home/container/game/csgo/addons/sourcemod/bin:$LD_LIBRARY_PATH
cd /home/container/game
exec ./cs2.sh "$@"
EOL
chmod +x /home/container/game/cs2_wrapper.sh

# Make cs2.sh executable if it exists
if [ -f "/home/container/game/cs2.sh" ]; then
    chmod +x /home/container/game/cs2.sh
fi

# Build startup command
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

# Add default parameters if using cs2.sh
if [[ ${MODIFIED_STARTUP} == *"cs2.sh"* ]]; then
    MODIFIED_STARTUP=${MODIFIED_STARTUP/cs2.sh/cs2_wrapper.sh}
    
    # Add required parameters
    [[ ${MODIFIED_STARTUP} != *"+ip 0.0.0.0"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +ip 0.0.0.0"
    [[ ${MODIFIED_STARTUP} != *"+port"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -port ${SRCDS_PORT:-25566}"
    [[ ${MODIFIED_STARTUP} != *"+map"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +map ${SRCDS_MAP:-workshop/2124557811/surf_beginner}"
    [[ ${MODIFIED_STARTUP} != *"+maxplayers"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -maxplayers ${SRCDS_MAXPLAYERS:-24}"
    [[ ${MODIFIED_STARTUP} != *"+clientport"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +clientport 27005"
    [[ ${MODIFIED_STARTUP} != *"+tv_port"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +tv_port 27020"
    [[ ${MODIFIED_STARTUP} != *"+sv_setsteamaccount"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_setsteamaccount ${STEAM_ACC:-anonymous}"
    [[ ${MODIFIED_STARTUP} != *"+game_type"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +game_type 0 +game_mode 0"
    [[ ${MODIFIED_STARTUP} != *"+host_workshop_collection"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +host_workshop_collection 2124557811"
    [[ ${MODIFIED_STARTUP} != *"+metamod_load"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +metamod_load"
    [[ ${MODIFIED_STARTUP} != *"+exec"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +exec sourcemod/surf.cfg"
fi

echo "Starting server with command: ${MODIFIED_STARTUP}"
eval ${MODIFIED_STARTUP}

# Copy custom configurations if they exist
echo "Setting up custom configurations..."
if [ -d "/home/container/configs" ]; then
    echo "Copying custom configs..."
    cp -rf /home/container/configs/* /home/container/game/csgo/cfg/
fi

# Handle plugins
echo "Setting up plugins..."
if [ ${COMPILE_PLUGINS:-0} -eq 1 ] && [ -d "/home/container/gamefiles/plugins/source" ]; then
    # Set up SourceMod compiler and compile plugins
    echo "Setting up SourceMod compiler..."
    mkdir -p /home/container/addons/sourcemod/scripting
    cd /home/container/addons/sourcemod/scripting

    # Download latest SourceMod compiler
    curl -sqL "https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7195-linux.tar.gz" | tar xzf - scripting/
    chmod +x spcomp

    # Compile all plugins in the source directory
    echo "Compiling plugins..."
    for plugin in /home/container/gamefiles/plugins/source/*.sp; do
        if [ -f "$plugin" ]; then
            echo "Compiling ${plugin}..."
            cp "$plugin" .
            ./spcomp $(basename "$plugin") -i"include" -o"/home/container/game/csgo/addons/sourcemod/plugins/$(basename "${plugin%.sp}").smx"
        fi
    done
else
    echo "Using pre-compiled plugins..."
fi

# Ensure proper permissions for plugins
chmod -R 755 /home/container/game/csgo/addons/sourcemod/plugins

# Create merged server configuration
echo "Creating merged server configuration..."
cat > /home/container/game/csgo/cfg/server.cfg << 'EOL'
// Load core CS2 configuration
exec sourcemod/cs2.cfg

// Load surf-specific configuration
exec sourcemod/surf.cfg

// Server identity
hostname "Nans Surf Server"
sv_tags "surf,timer,bhop"

// Workshop configuration
host_workshop_collection 2124557811
sv_workshop_allow_other_maps 1

// Network optimization
net_maxrate 786432
sv_minrate 128000
sv_maxrate 786432
sv_minupdaterate 128
sv_maxupdaterate 128
sv_mincmdrate 128
sv_maxcmdrate 128

// Game settings
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

// Movement settings
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

// Server settings
sv_infinite_ammo 2
sv_alltalk 1
sv_deadtalk 1
sv_allow_votes 0
sv_cheats 0
sv_pure 0
sv_pure_kick_clients 0
sv_steamauth_enforce 0
EOL

# Add CS2-specific startup parameters
if [[ ${MODIFIED_STARTUP} == *"cs2.sh"* ]]; then
    # Add CS2-specific parameters
    [[ ${MODIFIED_STARTUP} != *"-dedicated"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -dedicated"
    [[ ${MODIFIED_STARTUP} != *"-console"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -console"
    [[ ${MODIFIED_STARTUP} != *"-usercon"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -usercon"
    [[ ${MODIFIED_STARTUP} != *"+fps_max"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +fps_max 300"
    [[ ${MODIFIED_STARTUP} != *"+host_thread_mode"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +host_thread_mode 1"
    [[ ${MODIFIED_STARTUP} != *"+host_workers"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +host_workers 4"
    [[ ${MODIFIED_STARTUP} != *"+exec"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +exec server.cfg"
fi 