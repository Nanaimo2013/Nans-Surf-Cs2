#!/bin/bash
cd /home/container
sleep 1
# Output current environment
echo "Running on Debian $(cat /etc/debian_version)"
echo "Current timezone: $(cat /etc/timezone)"
echo "Current working directory: $(pwd)"

# Make internal Docker IP address available to processes
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`
echo "Internal IP: ${INTERNAL_IP}"

# Create necessary directories if they don't exist
mkdir -p /home/container/game/csgo/maps/workshop
mkdir -p /home/container/cfg
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64
mkdir -p /home/container/game/bin/linuxsteamrt64

# Install MetaMod and SourceMod if not already installed
if [ ! -f "/home/container/game/csgo/addons/metamod.vdf" ]; then
    echo "Installing MetaMod and SourceMod..."
    
    # Install MetaMod
    cd /home/container/game/csgo
    curl -sSL -o metamod.tar.gz https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz
    tar -xzvf metamod.tar.gz
    rm metamod.tar.gz
    
    # Install SourceMod
    curl -sSL -o sourcemod.tar.gz https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz
    tar -xzvf sourcemod.tar.gz
    rm sourcemod.tar.gz
    
    # Create MetaMod config
    cat > /home/container/game/csgo/addons/metamod.vdf << 'EOL'
"Plugin"
{
    "file"    "../csgo/addons/metamod/sourcemod.vdf"
}
EOL

    # Create SourceMod config
    cat > /home/container/game/csgo/addons/sourcemod.vdf << 'EOL'
"Plugin"
{
    "file"    "addons/sourcemod/bin/sourcemod_mm"
}
EOL
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

# Download and extract SteamCMD if not present
if [ ! -f "/home/container/steamcmd/steamcmd.sh" ]; then
    echo "Installing SteamCMD..."
    mkdir -p /home/container/steamcmd
    cd /home/container/steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    chmod +x steamcmd.sh
fi

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

# Download workshop maps if enabled and workshopmaps.txt exists
if [ ${DOWNLOAD_WORKSHOP_MAPS:-0} -eq 1 ] && [ -f "/home/container/workshopmaps.txt" ]; then
    echo "Downloading workshop maps..."
    while IFS= read -r map_id || [[ -n "$map_id" ]]; do
        if [[ $map_id =~ ^[0-9]+$ ]]; then
            echo "Downloading workshop item $map_id..."
            ${STEAMCMD} +login anonymous +workshop_download_item 730 $map_id +quit
        fi
    done < "/home/container/workshopmaps.txt"
fi

# Copy custom configurations if they exist
if [ -d "/home/container/configs" ]; then
    echo "Copying custom configs..."
    cp -rf /home/container/configs/* /home/container/game/csgo/cfg/
fi

# Set environment variable for XDG_RUNTIME_DIR to fix segmentation faults
export XDG_RUNTIME_DIR=/tmp/runtime-container
mkdir -p ${XDG_RUNTIME_DIR}
chmod 700 ${XDG_RUNTIME_DIR}

# Build startup command
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

# Add default parameters if using cs2.sh
if [[ ${MODIFIED_STARTUP} == *"cs2.sh"* ]]; then
    # Add required parameters
    [[ ${MODIFIED_STARTUP} != *"+ip 0.0.0.0"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +ip 0.0.0.0"
    [[ ${MODIFIED_STARTUP} != *"+port"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -port ${SRCDS_PORT:-25566}"
    [[ ${MODIFIED_STARTUP} != *"+map"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +map ${SRCDS_MAP:-de_dust2}"
    [[ ${MODIFIED_STARTUP} != *"+maxplayers"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} -maxplayers ${SRCDS_MAXPLAYERS:-24}"
    [[ ${MODIFIED_STARTUP} != *"+clientport"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +clientport 27005"
    [[ ${MODIFIED_STARTUP} != *"+tv_port"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +tv_port 27020"
    [[ ${MODIFIED_STARTUP} != *"+sv_setsteamaccount"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +sv_setsteamaccount ${STEAM_ACC:-anonymous}"
    [[ ${MODIFIED_STARTUP} != *"+game_type"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +game_type 0 +game_mode 0"
    [[ ${MODIFIED_STARTUP} != *"+host_workshop_collection"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +host_workshop_collection 2124557811"
    [[ ${MODIFIED_STARTUP} != *"+metamod_load"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +metamod_load"
    [[ ${MODIFIED_STARTUP} != *"+exec"* ]] && MODIFIED_STARTUP="${MODIFIED_STARTUP} +exec server.cfg +exec surf.cfg"
fi

echo "Starting server with command: ${MODIFIED_STARTUP}"
eval ${MODIFIED_STARTUP} 