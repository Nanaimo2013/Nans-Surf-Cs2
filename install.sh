#!/bin/bash
# CS2 Surf Server Installation Script
# Author: Nanaimo2013
# Description: Installation script for CS2 Surf Server

# Exit on any error
set -e

# Variables
STEAM_PATH="/home/container/steamcmd"
GAME_PATH="/home/container/game"
CS2_APPID="730"
METAMOD_URL="https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1282-linux.tar.gz"
SOURCEMOD_URL="https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git1234-linux.tar.gz"

# Create necessary directories
echo "Creating directories..."
mkdir -p "${STEAM_PATH}"
mkdir -p "${GAME_PATH}"
mkdir -p "${GAME_PATH}/csgo/addons"
mkdir -p "${GAME_PATH}/csgo/cfg/sourcemod"
mkdir -p "${GAME_PATH}/csgo/addons/sourcemod/plugins"
mkdir -p "${GAME_PATH}/csgo/addons/sourcemod/configs"
mkdir -p "${GAME_PATH}/csgo/materials"
mkdir -p "${GAME_PATH}/csgo/models"
mkdir -p "${GAME_PATH}/csgo/sound"

# Download and install SteamCMD
echo "Installing SteamCMD..."
curl -SL -o "${STEAM_PATH}/steamcmd_linux.tar.gz" "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
tar -xzvf "${STEAM_PATH}/steamcmd_linux.tar.gz" -C "${STEAM_PATH}"
rm "${STEAM_PATH}/steamcmd_linux.tar.gz"

# Install CS2 Dedicated Server
echo "Installing CS2 Dedicated Server..."
"${STEAM_PATH}/steamcmd.sh" +force_install_dir "${GAME_PATH}" +login anonymous +app_update "${CS2_APPID}" +quit

# Download and install MetaMod
echo "Installing MetaMod..."
curl -SL -o metamod.tar.gz "${METAMOD_URL}"
tar -xzvf metamod.tar.gz -C "${GAME_PATH}/csgo"
rm metamod.tar.gz

# Download and install SourceMod
echo "Installing SourceMod..."
curl -SL -o sourcemod.tar.gz "${SOURCEMOD_URL}"
tar -xzvf sourcemod.tar.gz -C "${GAME_PATH}/csgo"
rm sourcemod.tar.gz

# Copy server configurations
echo "Copying server configurations..."
cp -r ./gamefiles/configs/core/* "${GAME_PATH}/csgo/cfg/"
cp -r ./gamefiles/configs/sourcemod/* "${GAME_PATH}/csgo/cfg/sourcemod/"

# Copy plugins
echo "Installing plugins..."
cp -r ./gamefiles/plugins/compiled/*.smx "${GAME_PATH}/csgo/addons/sourcemod/plugins/"

# Copy data files
echo "Copying data files..."
cp -r ./gamefiles/data/* "${GAME_PATH}/csgo/addons/sourcemod/data/"

# Copy custom content (if exists)
echo "Copying custom content..."
if [ -d "./gamefiles/materials" ]; then
    cp -r ./gamefiles/materials/* "${GAME_PATH}/csgo/materials/"
fi

if [ -d "./gamefiles/models" ]; then
    cp -r ./gamefiles/models/* "${GAME_PATH}/csgo/models/"
fi

if [ -d "./gamefiles/sound" ]; then
    cp -r ./gamefiles/sound/* "${GAME_PATH}/csgo/sound/"
fi

# Set permissions
echo "Setting permissions..."
chmod -R 755 "${GAME_PATH}"
chmod -R 755 "${STEAM_PATH}"

# Create startup script
echo "Creating startup script..."
cat > start.sh << 'EOF'
#!/bin/bash
cd "${GAME_PATH}"
./cs2 -dedicated \
    +ip 0.0.0.0 \
    -port ${SERVER_PORT} \
    +map surf_beginner \
    +sv_setsteamaccount ${STEAM_ACC} \
    +exec cs2.cfg \
    +exec surf.cfg
EOF

chmod +x start.sh

echo "Installation complete!"
echo "Please make sure to:"
echo "1. Set your STEAM_ACC token in the environment variables"
echo "2. Configure your server ports (default: 27015)"
echo "3. Check all configuration files in cfg/ directory"
echo "4. Start the server using ./start.sh" 