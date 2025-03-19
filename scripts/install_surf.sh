#!/bin/bash

# Enhanced Surf Server Installation Script for CS2
set -euo pipefail

# GitHub Repository
GITHUB_REPO="https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main"

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
        if curl -sSL --fail "$url" -o "$target"; then
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
MAPS_DIR="$CSGO_DIR/maps"
WORKSHOP_DIR="$CSGO_DIR/maps/workshop"
CONFIGS_DIR="$CSGO_DIR/cfg"
PLUGINS_DIR="$SOURCEMOD_DIR/plugins"
SCRIPTING_DIR="$SOURCEMOD_DIR/scripting"

# Create required directories
create_directories() {
    log_message "Creating required directories..."
    mkdir -p "$MAPS_DIR"
    mkdir -p "$WORKSHOP_DIR"
    mkdir -p "$SOURCEMOD_DIR/configs/surf"
    mkdir -p "$PLUGINS_DIR"
    mkdir -p "$SCRIPTING_DIR"
    mkdir -p "$CONFIGS_DIR/sourcemod/surf"
}

# Download and setup SourceMod
setup_sourcemod() {
    log_message "Setting up SourceMod..."
    
    # Fetch latest SourceMod release for CS2
    local sm_release=$(curl -s https://api.github.com/repos/alliedmodders/sourcemod/releases/latest)
    local sm_download_url=$(echo "$sm_release" | grep -o 'https://.*sourcemod-.*-linux.tar.gz')
    
    if [ -z "$sm_download_url" ]; then
        handle_error "Could not find SourceMod download URL"
    fi
    
    download_file "$sm_download_url" "$BASE_DIR/sourcemod.tar.gz"
    tar -xzf "$BASE_DIR/sourcemod.tar.gz" -C "$SOURCEMOD_DIR"
    rm "$BASE_DIR/sourcemod.tar.gz"
}

# Download essential plugins
download_plugins() {
    log_message "Downloading essential plugins..."
    
    # Define plugins with their GitHub download URLs
    declare -A PLUGINS=(
        # Core Plugins
        ["surftimer"]="https://github.com/surftimer/SurfTimer/releases/latest/download/surftimer.smx"
        ["movementapi"]="https://github.com/danzayau/MovementAPI/releases/latest/download/MovementAPI.smx"
        
        # Admin Plugins
        ["adminmenu"]="https://github.com/alliedmodders/sourcemod/raw/master/plugins/adminmenu.smx"
        ["basecommands"]="https://github.com/alliedmodders/sourcemod/raw/master/plugins/basecommands.smx"
        
        # Utility Plugins
        ["mapchooser"]="https://github.com/alliedmodders/sourcemod/raw/master/plugins/mapchooser.smx"
        ["rockthevote"]="https://github.com/alliedmodders/sourcemod/raw/master/plugins/rockthevote.smx"
    )

    # Download each plugin
    for plugin_name in "${!PLUGINS[@]}"; do
        download_file "${PLUGINS[$plugin_name]}" "$PLUGINS_DIR/${plugin_name}.smx"
    done

    # Download our custom Nans Surf plugin
    download_file "${GITHUB_REPO}/plugins/nans_surf.sp" "$SCRIPTING_DIR/nans_surf.sp"
}

# Compile custom plugins
compile_plugins() {
    log_message "Compiling custom plugins..."
    cd "$SCRIPTING_DIR"
    
    # Check if spcomp exists
    if [ ! -f "./spcomp" ]; then
        handle_error "SourcePawn compiler (spcomp) not found"
    fi
    
    # Compile Nans Surf plugin
    ./spcomp nans_surf.sp -o ../plugins/nans_surf.smx
    cd "$BASE_DIR"
}

# Download configuration files
download_config_files() {
    log_message "Downloading configuration files..."
    
    # Configuration files to download
    local config_files=(
        "server.cfg"
        "workshop_maps.cfg"
        "maplist.txt"
    )
    
    for config in "${config_files[@]}"; do
        download_file "${GITHUB_REPO}/configs/${config}" "$CONFIGS_DIR/${config}"
    done

    # Additional SourceMod configuration files
    local sourcemod_configs=(
        "admins_simple.ini"
        "core.cfg"
        "databases.cfg"
    )

    for config in "${sourcemod_configs[@]}"; do
        download_file "${GITHUB_REPO}/configs/sourcemod/${config}" "$SOURCEMOD_DIR/configs/${config}"
    done
}

# Main installation routine
main() {
    log_message "Starting Nans Surf CS2 Server Installation..."
    
    create_directories
    setup_sourcemod
    download_plugins
    compile_plugins
    download_config_files
    
    # Set correct permissions
    chmod -R 755 "$SOURCEMOD_DIR"
    
    # Create installation complete marker
    touch "$BASE_DIR/.surf_installation_complete"
    
    log_message "Nans Surf CS2 Server Installation Complete!"
}

# Execute main routine
main 
