#!/bin/bash

# Comprehensive Surf Server Startup Script for CS2

# Strict error handling
set -euo pipefail

# GitHub Repository
GITHUB_REPO="https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main/scripts"

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
    
    # Increase timeout and add verbose error reporting
    if ! curl -sSL --fail --max-time 60 --retry 3 "$url" -o "$target"; then
        handle_error "Failed to download $url. Check network connection and URL."
    fi
    
    chmod +x "$target"
    log_message "Successfully downloaded $(basename "$target")"
}

# First-time installation
perform_first_time_install() {
    if [ ! -f "/home/container/.surf_installation_complete" ]; then
        log_message "Performing first-time installation..."
        
        # Ensure scripts directory exists
        mkdir -p /home/container/scripts
        
        # Download installation script
        if ! curl -sSL "https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main/scripts/install_surf.sh" -o "/home/container/scripts/install_surf.sh"; then
            handle_error "Failed to download installation script"
        fi
        
        # Make script executable
        chmod +x /home/container/scripts/install_surf.sh
        
        # Run the installation script
        if ! bash /home/container/scripts/install_surf.sh; then
            handle_error "Installation script failed"
        fi
    else
        log_message "Surf server already installed. Skipping installation."
    fi
}

# Validate required environment variables
validate_env_vars() {
    # Steam Account Token
    if [ -z "${STEAM_ACCOUNT:-}" ]; then
        log_message "WARNING: Steam Account Token is not set. Server may not start correctly."
    fi

    # Server Port
    if [ -z "${SERVER_PORT:-}" ]; then
        handle_error "SERVER_PORT environment variable is not set"
    fi
}

# Prepare server startup parameters
prepare_startup_params() {
    # Default map and settings
    STARTUP_MAP="${SRCDS_MAP:-surf_beginner}"
    MAX_PLAYERS="${SRCDS_MAXPLAYERS:-32}"

    # Prepare custom arguments
    CUSTOM_ARGS="${CUSTOM_STARTUP_ARGS:-}"

    # Log server details
    log_message "Starting CS2 Surf Server..."
    log_message "Map: $STARTUP_MAP"
    log_message "Max Players: $MAX_PLAYERS"
    log_message "Custom Args: $CUSTOM_ARGS"
}

# Main startup routine
main() {
    # Validate environment
    validate_env_vars

    # Perform first-time installation if needed
    perform_first_time_install

    # Prepare startup parameters
    prepare_startup_params

    # Start server with comprehensive arguments
    cd /home/container/game/csgo
    /home/container/game/cs2.sh -dedicated \
        +ip 0.0.0.0 \
        -port "${SERVER_PORT}" \
        +map "$STARTUP_MAP" \
        -maxplayers "$MAX_PLAYERS" \
        +sv_setsteamaccount "${STEAM_ACCOUNT:-}" \
        +exec "/home/container/game/csgo/cfg/server.cfg" \
        +exec "/home/container/game/csgo/cfg/workshop_maps.cfg" \
        ${CUSTOM_STARTUP_ARGS}
}

# Execute main routine
main

# Exit script after logging (server will be started by main command)
exit 0 