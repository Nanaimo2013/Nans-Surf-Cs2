#!/bin/bash

# Enhanced Surf Server Installation Script for CS2
set -euo pipefail

# Logging function
log_message() {
    echo "[Nans Surf Install] $1"
}

# Error handling function
handle_error() {
    log_message "ERROR: $1"
    exit 1
}

# Download function with retry
download_file() {
    local url="$1"
    local target="$2"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if curl -sSL --fail --max-time 60 "$url" -o "$target"; then
            log_message "Successfully downloaded $url to $target"
            return 0
        else
            retry_count=$((retry_count + 1))
            log_message "Download failed (attempt $retry_count/$max_retries): $url"
            sleep 2
        fi
    done

    handle_error "Failed to download $url after $max_retries attempts"
}

# Define directories
BASE_DIR="/home/container"
GAME_DIR="${BASE_DIR}/game"
CSGO_DIR="${GAME_DIR}/csgo"
SOURCEMOD_DIR="$CSGO_DIR/addons/sourcemod"
MAPS_DIR="$BASE_DIR/maps"
WORKSHOP_DIR="$MAPS_DIR/workshop"
CONFIGS_DIR="$BASE_DIR/configs"
PLUGINS_DIR="$BASE_DIR/plugins"
SCRIPTING_DIR="$SOURCEMOD_DIR/scripting"
INCLUDE_DIR="$SOURCEMOD_DIR/scripting/include"

# Create required directories
create_directories() {
    log_message "Creating required directories..."
    mkdir -p "$MAPS_DIR"
    mkdir -p "$WORKSHOP_DIR"
    mkdir -p "$SOURCEMOD_DIR/configs/surf"
    mkdir -p "$SOURCEMOD_DIR/plugins"
    mkdir -p "$SCRIPTING_DIR"
    mkdir -p "$INCLUDE_DIR"
    mkdir -p "$CSGO_DIR/cfg/sourcemod/surf"
}

# Download and setup SourceMod
setup_sourcemod() {
    log_message "Setting up SourceMod..."
    
    # Hardcoded, stable SourceMod download URL for CS2
    local sm_download_url="https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz"
    
    download_file "$sm_download_url" "$BASE_DIR/sourcemod.tar.gz"
    
    # Extract with error handling
    if ! tar -xzf "$BASE_DIR/sourcemod.tar.gz" -C "$SOURCEMOD_DIR"; then
        handle_error "Failed to extract SourceMod archive"
    fi
    
    rm "$BASE_DIR/sourcemod.tar.gz"
}

# Download essential include files
download_include_files() {
    log_message "Downloading include files..."
    
    # Define include files to download
    declare -A INCLUDE_SOURCES=(
        ["multicolors.inc"]="https://raw.githubusercontent.com/Bara/Multi-Colors/master/scripting/include/multicolors.inc"
        ["timer.inc"]="https://raw.githubusercontent.com/surftimer/SurfTimer/master/scripting/include/surftimer.inc"
        ["mysql.inc"]="https://raw.githubusercontent.com/alliedmodders/sourcemod/master/plugins/include/mysql.inc"
    )

    # Download each include file
    for include_name in "${!INCLUDE_SOURCES[@]}"; do
        download_file "${INCLUDE_SOURCES[$include_name]}" "$INCLUDE_DIR/${include_name}"
    done
}

# Copy local plugins and configurations
copy_local_files() {
    log_message "Copying local plugins and configurations..."

    # Copy local plugins
    if [ -d "$BASE_DIR/plugins" ]; then
        cp "$BASE_DIR/plugins/"*.sp "$SCRIPTING_DIR/"
    fi

    # Copy local configurations
    if [ -d "$BASE_DIR/configs/surf" ]; then
        cp "$BASE_DIR/configs/surf/"* "$SOURCEMOD_DIR/configs/surf/"
    fi

    # Copy local maps
    if [ -d "$BASE_DIR/maps" ]; then
        cp "$BASE_DIR/maps/"*.bsp "$CSGO_DIR/maps/"
        cp "$BASE_DIR/maps/workshop/"*.bsp "$CSGO_DIR/maps/workshop/" 2>/dev/null || true
    fi
}

# Compile local plugins
compile_local_plugins() {
    log_message "Compiling local plugins..."
    
    # Find spcomp compiler
    local spcomp=$(find "$SOURCEMOD_DIR" -name "spcomp" | head -n 1)
    
    if [ -z "$spcomp" ]; then
        log_message "WARNING: SourcePawn compiler not found. Skipping plugin compilation."
        return
    fi

    # Compile all .sp files in scripting directory
    cd "$SCRIPTING_DIR"
    for sp_file in *.sp; do
        if [ -f "$sp_file" ]; then
            plugin_name="${sp_file%.*}"
            log_message "Compiling $sp_file to ${plugin_name}.smx"
            
            if ! "$spcomp" "$sp_file" -o "../plugins/${plugin_name}.smx"; then
                log_message "WARNING: Failed to compile $sp_file"
            fi
        fi
    done
    cd "$BASE_DIR"
}

# Steam Game Server Account setup
setup_steam_account() {
    # Check if Steam Account Token is set
    if [ -z "${STEAM_ACCOUNT:-}" ]; then
        log_message "WARNING: Steam Account Token is not set. Server may not start correctly."
        return
    fi

    # Create a file with Steam Account Token
    log_message "Setting up Steam Game Server Account"
    echo "sv_setsteamaccount ${STEAM_ACCOUNT}" > "$CSGO_DIR/cfg/steam_account.cfg"
}

# Main installation routine
main() {
    log_message "Starting Nans Surf CS2 Server Installation..."
    
    create_directories
    setup_sourcemod
    download_include_files
    copy_local_files
    compile_local_plugins
    setup_steam_account
    
    # Set correct permissions
    chmod -R 755 "$SOURCEMOD_DIR"
    
    # Create installation complete marker
    touch "$BASE_DIR/.surf_installation_complete"
    
    log_message "Nans Surf CS2 Server Installation Complete!"
}

# Execute main routine
main 
