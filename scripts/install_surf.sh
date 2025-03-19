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

# Download function with retry and optional logging
download_file() {
    local url="$1"
    local target="$2"
    local max_retries=3
    local retry_count=0
    local silent="${3:-false}"

    # Ensure target directory exists
    mkdir -p "$(dirname "$target")"

    while [ $retry_count -lt $max_retries ]; do
        if [ "$silent" = "true" ]; then
            if curl -sSL --fail --max-time 60 "$url" -o "$target" 2>/dev/null; then
                return 0
            fi
        else
            if curl -sSL --fail --max-time 60 "$url" -o "$target"; then
                log_message "Successfully downloaded $url to $target"
                return 0
            fi
        fi

        retry_count=$((retry_count + 1))
        log_message "Download failed (attempt $retry_count/$max_retries): $url"
        sleep 2
    done

    return 1
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

# GitHub repository base URL
REPO_BASE_URL="https://raw.githubusercontent.com/Nanaimo2013/Nans-Surf-Cs2/main"

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
    log_message "Downloading essential include files..."
    
    # Define include files to download
    declare -A INCLUDE_SOURCES=(
        ["multicolors.inc"]="https://raw.githubusercontent.com/Bara/Multi-Colors/master/scripting/include/multicolors.inc"
        ["timer.inc"]="https://raw.githubusercontent.com/surftimer/SurfTimer/master/scripting/include/surftimer.inc"
    )

    # Ensure include directory exists
    mkdir -p "$INCLUDE_DIR"

    # Download each include file
    for include_name in "${!INCLUDE_SOURCES[@]}"; do
        log_message "Downloading $include_name..."
        if ! download_file "${INCLUDE_SOURCES[$include_name]}" "$INCLUDE_DIR/${include_name}" "true"; then
            log_message "WARNING: Could not download $include_name. Plugin may not compile correctly."
        fi
    done
}

# Download configuration files from GitHub
download_config_files() {
    log_message "Downloading configuration files..."

    # Configuration files to download
    local config_files=(
        "configs/surf/server.cfg"
        "configs/surf/workshop_maps.cfg"
        "configs/surf/maplist.txt"
        "configs/surf/maptiers.cfg"
        "configs/surf/admin_commands.cfg"
        "configs/surf/hud.cfg"
        "configs/surf/quickmenu.cfg"
        "configs/surf/storage.cfg"
        "configs/surf/surf_advertisements.cfg"
    )

    for config in "${config_files[@]}"; do
        local target_path="$SOURCEMOD_DIR/${config}"
        download_file "${REPO_BASE_URL}/${config}" "$target_path"
    done

    # Create autoexec.cfg
    mkdir -p "$CSGO_DIR/cfg"
    cat > "$CSGO_DIR/cfg/autoexec.cfg" << EOL
// Auto-execute configuration
exec server.cfg
exec workshop_maps.cfg
EOL
}

# Download plugins from GitHub
download_plugins() {
    log_message "Downloading plugins..."

    # Plugins to download
    local plugins=(
        "plugins/nans_surf.sp"
    )

    for plugin in "${plugins[@]}"; do
        local target_path="$SCRIPTING_DIR/$(basename "$plugin")"
        download_file "${REPO_BASE_URL}/${plugin}" "$target_path"
    done
}

# Download maps from GitHub
download_maps() {
    log_message "Downloading maps..."

    # Map download URLs (you may need to adjust these)
    declare -A MAP_SOURCES=(
        ["surf_beginner.bsp"]="${REPO_BASE_URL}/maps/surf_beginner.bsp"
        ["surf_easy_v2.bsp"]="${REPO_BASE_URL}/maps/surf_easy_v2.bsp"
        ["surf_rookie.bsp"]="${REPO_BASE_URL}/maps/surf_rookie.bsp"
        ["surf_mesa.bsp"]="${REPO_BASE_URL}/maps/surf_mesa.bsp"
    )

    # Download maps to game maps directory
    for map_name in "${!MAP_SOURCES[@]}"; do
        download_file "${MAP_SOURCES[$map_name]}" "$CSGO_DIR/maps/$map_name"
    done
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
            
            # Compile with include path and ignore certain errors
            if ! "$spcomp" -i"$INCLUDE_DIR" "$sp_file" -o"../plugins/${plugin_name}.smx"; then
                log_message "WARNING: Failed to compile $sp_file completely. Continuing..."
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
    download_config_files
    download_plugins
    download_maps
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
