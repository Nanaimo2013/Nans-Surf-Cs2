#!/bin/bash

# Comprehensive Surf Server Startup Script

# Logging function
log_message() {
    echo "[Nans Surf Server] $1"
}

# Always run installation if flag doesn't exist
if [ ! -f "/home/container/.surf_installation_complete" ]; then
    log_message "Performing first-time installation..."
    
    # Run installation script
    if [ -f "/home/container/install_surf.sh" ]; then
        bash /home/container/install_surf.sh
        touch "/home/container/.surf_installation_complete"
    else
        log_message "ERROR: install_surf.sh not found!"
        exit 1
    fi
fi

# Validate Steam Account
if [ -z "$STEAM_ACCOUNT" ]; then
    log_message "WARNING: Steam Account Token is not set!"
fi

# Default map and settings
STARTUP_MAP="${SRCDS_MAP:-surf_beginner}"
MAX_PLAYERS="${SRCDS_MAXPLAYERS:-32}"

# Prepare custom arguments (remove installation commands)
CUSTOM_ARGS="${CUSTOM_STARTUP_ARGS}"

# Log and execute
log_message "Starting CS2 Surf Server..."
log_message "Map: $STARTUP_MAP"
log_message "Max Players: $MAX_PLAYERS"
log_message "Custom Args: $CUSTOM_ARGS"

# Exit script after logging (server will be started by main command)
exit 0 