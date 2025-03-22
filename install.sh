#!/bin/bash
# CS2 Surf Server Installation Script
#
# Server Files: /home/container

## Default to anonymous login if no Steam credentials provided
if [ "${STEAM_USER}" == "" ]; then
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

## Prepare installation environment
cd /tmp
mkdir -p /home/container/steamcmd
mkdir -p /home/container/game/csgo

## Download and install SteamCMD
echo "Downloading SteamCMD..."
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf steamcmd.tar.gz -C /home/container/steamcmd
rm steamcmd.tar.gz
cd /home/container/steamcmd

## Install required dependencies
echo "Installing dependencies..."
if [ -f "/etc/debian_version" ]; then
    apt-get update
    apt-get install -y lib32gcc-s1 lib32stdc++6 lib32z1 curl wget tar
fi

## Set proper permissions
chown -R container:container /home/container
export HOME=/home/container

## Install CS2 using SteamCMD
echo "Installing CS2..."
./steamcmd.sh \
    +force_install_dir /home/container \
    +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
    +app_update 730 ${EXTRA_FLAGS} \
    +quit

## Set up Steam libraries
echo "Setting up Steam libraries..."
mkdir -p /home/container/.steam/sdk32
mkdir -p /home/container/.steam/sdk64
cp -v linux32/steamclient.so /home/container/.steam/sdk32/steamclient.so
cp -v linux64/steamclient.so /home/container/.steam/sdk64/steamclient.so

## Download and install MetaMod
echo "Installing MetaMod..."
mkdir -p /home/container/game/csgo/addons
cd /home/container/game/csgo
curl -sSL -o metamod.tar.gz https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz
tar -xzvf metamod.tar.gz
rm metamod.tar.gz

## Download and install SourceMod
echo "Installing SourceMod..."
curl -sSL -o sourcemod.tar.gz https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz
tar -xzvf sourcemod.tar.gz
rm sourcemod.tar.gz

## Create CS2 startup script
cat > /home/container/game/cs2.sh << 'EOL'
#!/bin/bash
export LD_LIBRARY_PATH="./bin:$LD_LIBRARY_PATH"
./bin/linuxsteamrt64/cs2
EOL
chmod +x /home/container/game/cs2.sh

## Create necessary directories
mkdir -p /home/container/game/csgo/cfg
mkdir -p /home/container/game/csgo/addons/sourcemod/plugins
mkdir -p /home/container/game/csgo/addons/sourcemod/configs
mkdir -p /home/container/game/csgo/addons/sourcemod/data

## Optional: Validate installation
if [ "${SRCDS_VALIDATE}" == "1" ]; then
    echo "Validating installation..."
    ./steamcmd.sh \
        +force_install_dir /home/container \
        +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
        +app_update 730 validate \
        +quit
fi

## Final permissions adjustment
chown -R container:container /home/container
chmod -R 755 /home/container

echo "Installation completed successfully" 