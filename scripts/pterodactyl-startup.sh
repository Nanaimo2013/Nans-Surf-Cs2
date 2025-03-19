#!/bin/bash

# Comprehensive Surf Server Startup Script for CS2

# Strict error handling
set -euo pipefail

# GitHub Repository
GITHUB_REPO="https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main"

# Logging function
log_message() {
    echo "[Nans Surf Server] $1"
}

# Error handling function
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

# Download function with robust error handling
download_file() {
    local url="$1"
    local target="$2"
    
    log_message "Downloading: $url"
    
    if ! curl -sSL --fail --max-time 60 --retry 3 "$url" -o "$target"; then
        handle_error "Failed to download $url"
    fi
    
    chmod +x "$target"
    log_message "Successfully downloaded $(basename "$target")"
}

# First-time installation
perform_first_time_install() {
    if [ ! -f "/home/container/.surf_installation_complete" ]; then
        log_message "Performing first-time installation..."
        
        # Create necessary directories
        mkdir -p /home/container/game/csgo/cfg
        mkdir -p /home/container/game/csgo/addons/sourcemod/configs/surf
        
        # Download configurations
        download_file "$GITHUB_REPO/cfg/server.cfg" "/home/container/game/csgo/cfg/server.cfg"
        download_file "$GITHUB_REPO/cfg/workshop_maps.cfg" "/home/container/game/csgo/cfg/workshop_maps.cfg"
        
        # Download SourceMod plugins
        mkdir -p /home/container/game/csgo/addons/sourcemod/plugins
        download_file "$GITHUB_REPO/plugins/nans_surf.smx" "/home/container/game/csgo/addons/sourcemod/plugins/nans_surf.smx"
        download_file "$GITHUB_REPO/plugins/nans_surftimer.smx" "/home/container/game/csgo/addons/sourcemod/plugins/nans_surftimer.smx"
        
        # Download timer components
        mkdir -p /home/container/game/csgo/addons/sourcemod/plugins/nans_surftimer
        for component in zones database player_manager map_manager leaderboard replay_system; do
            download_file "$GITHUB_REPO/plugins/nans_surftimer/${component}.sp" "/home/container/game/csgo/addons/sourcemod/plugins/nans_surftimer/${component}.sp"
        done
        
        # Mark installation as complete
        touch /home/container/.surf_installation_complete
        log_message "Installation completed successfully"
    else
        log_message "Surf server already installed"
    fi
}

# Validate required environment variables
validate_env_vars() {
    if [ -z "${STEAM_ACCOUNT:-}" ]; then
        log_message "ERROR: Steam Game Server Login Token is REQUIRED"
        log_message "Please set the STEAM_ACCOUNT environment variable in your Pterodactyl panel"
        log_message "Get a token from: https://steamcommunity.com/dev/managegameservers"
        exit 1
    fi

    if [ -z "${SERVER_PORT:-}" ]; then
        handle_error "SERVER_PORT environment variable is not set"
    fi
}

# Update server.cfg with Steam token
update_server_cfg() {
    local cfg_file="/home/container/game/csgo/cfg/server.cfg"
    if [ -f "$cfg_file" ]; then
        sed -i "s/sv_setsteamaccount .*/sv_setsteamaccount \"${STEAM_ACCOUNT}\"/" "$cfg_file"
    fi
}

# Main startup routine
main() {
    validate_env_vars
    perform_first_time_install
    update_server_cfg

    # Start CS2 server
    cd /home/container/game || exit 1
    
    # Build startup command
    STARTUP_CMD="./cs2 -dedicated \
        -console \
        -usercon \
        -port ${SERVER_PORT} \
        -maxplayers ${MAXPLAYERS:-24} \
        +map ${SRCDS_MAP:-surf_beginner} \
        +sv_setsteamaccount ${STEAM_ACCOUNT} \
        +exec server.cfg \
        +exec workshop_maps.cfg \
        ${ADDITIONAL_ARGS:-}"

    # Execute the server
    log_message "Starting CS2 Surf Server..."
    eval "$STARTUP_CMD"
}

# Execute main routine
main

# Exit script after logging (server will be started by main command)
exit 0 