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

# Update CS2 Server
echo "Updating CS2 Server..."
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login ${STEAM_ACC} +app_update ${SRCDS_APPID} ${SRCDS_VALIDATE:++validate} +quit

# Default the Network Port to 25566
export SRCDS_PORT=25566
export SRCDS_MAXPLAYERS=64
export SRCDS_STARTMAP="de_dust2"
export SRCDS_HOSTNAME="Nans Surf CS2 Server"
export SRCDS_TAGS="surf,tier1,timer"

# Replace Startup Variables
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{SERVER_PORT}}/'"${SRCDS_PORT}"'/' \
    -e 's/{{SERVER_MAXPLAYERS}}/'"${SRCDS_MAXPLAYERS}"'/' \
    -e 's/{{SERVER_MAP}}/'"${SRCDS_STARTMAP}"'/' \
    -e 's/{{SERVER_HOSTNAME}}/'"${SRCDS_HOSTNAME}"'/' \
    -e 's/{{SERVER_TAGS}}/'"${SRCDS_TAGS}"'/')

# Start the Server
echo "Starting server with command: ${MODIFIED_STARTUP}"
eval ${MODIFIED_STARTUP} 