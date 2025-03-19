#!/bin/bash
cd /home/container

# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`

# Create necessary directories
mkdir -p /home/container/game/csgo/maps/workshop
mkdir -p /home/container/cfg
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64

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
    fi
fi

# Download workshop maps if needed
if [ ! -z ${DOWNLOAD_WORKSHOP_MAPS} ] && [ ${DOWNLOAD_WORKSHOP_MAPS} -eq 1 ]; then
    echo "Downloading workshop maps..."
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053395359 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053703590 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053706898 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053712237 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053715412 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053718896 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053722154 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053725698 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053729012 +quit
    ./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container/game +workshop_download_item 730 3053732456 +quit
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

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP} 