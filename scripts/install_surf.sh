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

# Create required directories
create_directories() {
    log_message "Creating required directories..."
    mkdir -p "$MAPS_DIR"
    mkdir -p "$WORKSHOP_DIR"
    mkdir -p "$SOURCEMOD_DIR/configs/surf"
    mkdir -p "$SOURCEMOD_DIR/plugins"
    mkdir -p "$SOURCEMOD_DIR/scripting"
    mkdir -p "$CONFIGS_DIR/sourcemod/surf"
}

# Download and setup SourceMod
setup_sourcemod() {
    log_message "Setting up SourceMod..."
    
    # Hardcoded SourceMod download URL for CS2
    local sm_download_url="https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-linux.tar.gz"
    
    if [ -z "$sm_download_url" ]; then
        handle_error "Could not find SourceMod download URL"
    fi
    
    download_file "$sm_download_url" "$BASE_DIR/sourcemod.tar.gz"
    tar -xzf "$BASE_DIR/sourcemod.tar.gz" -C "$SOURCEMOD_DIR"
    rm "$BASE_DIR/sourcemod.tar.gz"
}

# Download project files
download_project_files() {
    log_message "Downloading project files..."
    
    # Download plugin
    download_file "${GITHUB_REPO}/plugins/nans_surf.sp" "$SOURCEMOD_DIR/scripting/nans_surf.sp"
    
    # Download configuration files
    local config_files=(
        "server.cfg"
        "workshop_maps.cfg"
        "maplist.txt"
    )
    
    for config in "${config_files[@]}"; do
        download_file "${GITHUB_REPO}/configs/${config}" "$CONFIGS_DIR/${config}"
    done
}

# Compile Nans Surf Plugin
compile_plugin() {
    log_message "Compiling Nans Surf Plugin..."
    cd "$SOURCEMOD_DIR/scripting"
    
    # Check if spcomp exists
    if [ ! -f "./spcomp" ]; then
        handle_error "SourcePawn compiler (spcomp) not found"
    fi
    
    ./spcomp nans_surf.sp -o ../plugins/nans_surf.smx
    cd "$BASE_DIR"
}

# Main installation routine
main() {
    log_message "Starting Nans Surf CS2 Server Installation..."
    
    create_directories
    setup_sourcemod
    download_project_files
    compile_plugin
    
    # Create installation complete marker
    touch "$BASE_DIR/.surf_installation_complete"
    
    log_message "Nans Surf CS2 Server Installation Complete!"
}

# Execute main routine
main 
