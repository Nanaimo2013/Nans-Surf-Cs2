#!/bin/bash
cd /home/container

# Output Current System Information
echo "Running on Debian $(cat /etc/debian_version)"
echo "Current timezone: $(cat /etc/timezone)"
echo "Current working directory: $(pwd)"
echo "Internal IP: $(hostname -i | awk '{print $1}')"

# Set up Steam Environment
echo "Setting up Steam environment..."
mkdir -p /home/container/Steam/logs

# Create cs2.sh if it doesn't exist
cat > /home/container/game/cs2.sh << 'EOL'
#!/bin/bash
cd /home/container/game
export LD_LIBRARY_PATH="./bin:$LD_LIBRARY_PATH"
exec ./bin/linuxsteamrt64/cs2 "$@"
EOL
chmod +x /home/container/game/cs2.sh

# Default variables
SRCDS_PORT="${SERVER_PORT:-25566}"
SRCDS_MAXPLAYERS="${SERVER_MAXPLAYERS:-64}"
SRCDS_MAP="${SERVER_MAP:-de_dust2}"
SERVER_NAME="${SERVER_NAME:-Nans Surf CS2 Server}"
SURF_TIER="${SURF_TIER:-1}"
STEAM_ACC="${STEAM_ACC:-anonymous}"

# Build startup command
MODIFIED_STARTUP="./game/cs2.sh -dedicated +ip 0.0.0.0 -port ${SRCDS_PORT} +hostname \"${SERVER_NAME}\" +map ${SRCDS_MAP} -maxplayers ${SRCDS_MAXPLAYERS} +sv_setsteamaccount ${STEAM_ACC} +exec server.cfg +exec surf.cfg +sv_tags \"surf,tier${SURF_TIER},timer\" +clientport 27005 +tv_port 27020 +game_type 0 +game_mode 0 +host_workshop_collection 2124557811 +metamod_load"

# Start the Server
echo "Starting server with command: ${MODIFIED_STARTUP}"
eval ${MODIFIED_STARTUP} 