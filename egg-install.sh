#!/bin/ash
cd /mnt/server

# Install required dependencies
apk add --no-cache curl tar bash wget ca-certificates

# Create base directory structure
mkdir -p /mnt/server/steamcmd
mkdir -p /mnt/server/cs2
mkdir -p /mnt/server/cs2/game/csgo/{addons,cfg,materials,models,sound}
mkdir -p /mnt/server/cs2/game/csgo/addons/sourcemod/{configs,data,plugins}
mkdir -p /mnt/server/cs2/game/csgo/cfg/sourcemod

# Download SteamCMD
cd /mnt/server/steamcmd
wget -q http://media.steampowered.com/installer/steamcmd_linux.tar.gz
tar -xzf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz

# Install CS2 Server
./steamcmd.sh +force_install_dir /mnt/server/cs2/game +login anonymous +app_update 730 validate +quit

# Download and install MetaMod
cd /mnt/server/cs2/game/csgo
wget -q https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1282-linux.tar.gz -O metamod.tar.gz
tar -xzf metamod.tar.gz
rm metamod.tar.gz

# Download and install SourceMod
wget -q https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git1234-linux.tar.gz -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz
rm sourcemod.tar.gz

# Create basic server configs
cat > /mnt/server/cs2/game/csgo/cfg/server.cfg << 'EOF'
hostname "Nans CS2 Surf Server"
sv_lan 0
sv_region 3
sv_tags "surf,timer,bhop"
sv_allowupload 1
sv_allowdownload 1
sv_maxrate 0
sv_minrate 100000
sv_maxcmdrate 128
sv_mincmdrate 30
sv_maxupdaterate 128
sv_minupdaterate 30
sv_password ""
rcon_password "${RCON_PASSWORD}"
sv_maxplayers "${MAX_PLAYERS}"
EOF

# Create startup script
cat > /mnt/server/start.sh << 'EOF'
#!/bin/bash
cd /mnt/server/cs2/game

# Update server before starting
/mnt/server/steamcmd/steamcmd.sh +force_install_dir /mnt/server/cs2/game +login anonymous +app_update 730 +quit

# Start the server
./cs2 -dedicated \
    +ip 0.0.0.0 \
    -port ${SERVER_PORT} \
    +map surf_beginner \
    +sv_setsteamaccount ${STEAM_ACC} \
    +exec server.cfg \
    +exec surf.cfg
EOF

chmod +x /mnt/server/start.sh

echo "Installation completed successfully" 