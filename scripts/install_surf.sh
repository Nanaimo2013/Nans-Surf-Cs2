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
    
    # Hardcoded, stable SourceMod download URL for CS2
    local sm_download_url="https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz"
    
    download_file "$sm_download_url" "$BASE_DIR/sourcemod.tar.gz"
    
    # Extract with error handling
    if ! tar -xzf "$BASE_DIR/sourcemod.tar.gz" -C "$SOURCEMOD_DIR"; then
        handle_error "Failed to extract SourceMod archive"
    fi
    
    rm "$BASE_DIR/sourcemod.tar.gz"
}

# Download essential plugins
download_plugins() {
    log_message "Downloading essential plugins..."
    
    # Define plugins with their download URLs
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

    # Download our custom Nans Surf plugin source
    download_file "https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main/plugins/nans_surf.sp" "$SCRIPTING_DIR/nans_surf.sp"
}

# Compile custom plugins
compile_plugins() {
    log_message "Compiling custom plugins..."
    cd "$SCRIPTING_DIR"
    
    # Verify spcomp exists
    if [ ! -f "./spcomp" ]; then
        # Try to find spcomp in SourceMod directory
        local spcomp_path=$(find "$SOURCEMOD_DIR" -name "spcomp" | head -n 1)
        
        if [ -z "$spcomp_path" ]; then
            handle_error "SourcePawn compiler (spcomp) not found"
        fi
        
        # Use found spcomp path
        spcomp="$spcomp_path"
    else
        spcomp="./spcomp"
    fi
    
    # Compile Nans Surf plugin
    if ! "$spcomp" nans_surf.sp -o ../plugins/nans_surf.smx; then
        handle_error "Failed to compile nans_surf.sp"
    fi
    
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
        download_file "https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main/configs/${config}" "$CONFIGS_DIR/${config}"
    done

    # Additional SourceMod configuration files
    local sourcemod_configs=(
        "admins_simple.ini"
        "core.cfg"
        "databases.cfg"
    )

    for config in "${sourcemod_configs[@]}"; do
        download_file "https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main/configs/sourcemod/${config}" "$SOURCEMOD_DIR/configs/${config}"
    done
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
    echo "sv_setsteamaccount ${STEAM_ACCOUNT}" > "$CONFIGS_DIR/steam_account.cfg"
}

# Main installation routine
main() {
    log_message "Starting Nans Surf CS2 Server Installation..."
    
    create_directories
    setup_sourcemod
    download_plugins
    compile_plugins
    download_config_files
    setup_steam_account
    
    # Set correct permissions
    chmod -R 755 "$SOURCEMOD_DIR"
    
    # Create installation complete marker
    touch "$BASE_DIR/.surf_installation_complete"
    
    log_message "Nans Surf CS2 Server Installation Complete!"
}

# Execute main routine
main 
