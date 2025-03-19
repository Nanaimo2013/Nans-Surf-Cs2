#!/bin/bash

# Nans Surf CS2 Server Setup Script
# Version 1.0.0

# Strict error handling
set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[NANS SURF SETUP]${NC} $1"
}

# Error handling function
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Dependency check
check_dependencies() {
    log "Checking dependencies..."
    
    # Check for required tools
    local dependencies=("wget" "unzip" "curl" "git")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "$dep is not installed. Please install it and try again."
        fi
    done
}

# Download SourceMod
download_sourcemod() {
    log "Downloading SourceMod for CS2..."
    
    # Fetch latest SourceMod release for CS2
    local sm_release=$(curl -s https://api.github.com/repos/alliedmodders/sourcemod/releases/latest)
    local sm_download_url=$(echo "$sm_release" | grep -o 'https://.*sourcemod-.*-linux.tar.gz')
    
    if [ -z "$sm_download_url" ]; then
        error "Could not find SourceMod download URL"
    fi
    
    wget -O sourcemod.tar.gz "$sm_download_url"
    tar -xzf sourcemod.tar.gz -C addons/sourcemod/
    rm sourcemod.tar.gz
    
    log "SourceMod installed successfully"
}

# Download Essential Plugins
download_plugins() {
    log "Downloading essential plugins..."
    
    # Create plugins directory
    mkdir -p addons/sourcemod/plugins
    
    # Plugin download URLs (replace with actual verified URLs)
    local plugins=(
        "https://github.com/surftimer/SurfTimer/releases/latest/download/surftimer.smx"
        "https://github.com/danzayau/MovementAPI/releases/latest/download/movementapi.smx"
        "https://github.com/peace-maker/DHooks2/releases/latest/download/dhooks.smx"
    )
    
    for plugin in "${plugins[@]}"; do
        wget -O "addons/sourcemod/plugins/$(basename "$plugin")" "$plugin"
    done
    
    log "Plugins downloaded successfully"
}

# Compile Nans Surf Plugin
compile_nans_surf_plugin() {
    log "Compiling Nans Surf Plugin..."
    
    # Check if spcomp (SourcePawn compiler) exists
    if [ ! -f "addons/sourcemod/scripting/spcomp" ]; then
        error "SourcePawn compiler not found. Ensure SourceMod is installed correctly."
    fi
    
    # Compile the plugin
    cd addons/sourcemod/scripting
    ./spcomp nans_surf.sp -o ../plugins/nans_surf.smx
    cd ../../..
    
    log "Nans Surf Plugin compiled successfully"
}

# Create Workshop Collection Configuration
create_workshop_config() {
    log "Creating Workshop Collection Configuration..."
    
    cat > cfg/workshop_maps.cfg << EOL
// Workshop Map Collection for Nans Surf Server
// Format: workshop_download_map <workshop_id>

// Tier 1 - Beginner Maps
workshop_download_map 3141592653 // surf_beginner
workshop_download_map 3141592654 // surf_easy_v2
workshop_download_map 3141592655 // surf_rookie
workshop_download_map 3141592656 // surf_mesa

// Tier 2 - Easy Maps
workshop_download_map 3141592657 // surf_utopia
workshop_download_map 3141592658 // surf_kitsune
workshop_download_map 3141592659 // surf_summer
workshop_download_map 3141592660 // surf_japan_ptad

// Tier 3 - Medium Maps
workshop_download_map 3141592661 // surf_aircontrol
workshop_download_map 3141592662 // surf_catalyst
workshop_download_map 3141592663 // surf_paradise
workshop_download_map 3141592664 // surf_classics

// Tier 4 - Hard Maps
workshop_download_map 3141592665 // surf_ace
workshop_download_map 3141592666 // surf_rebel
workshop_download_map 3141592667 // surf_network
workshop_download_map 3141592668 // surf_greatriver

// Tier 5 - Expert Maps
workshop_download_map 3141592669 // surf_forbidden_ways
workshop_download_map 3141592670 // surf_nightmare
workshop_download_map 3141592671 // surf_expert

// Special Maps
workshop_download_map 3141592672 // surf_christmas
workshop_download_map 3141592673 // surf_halloween
workshop_download_map 3141592674 // surf_summer_party
EOL

    log "Workshop configuration created"
}

# Main setup function
main() {
    log "Starting Nans Surf CS2 Server Setup..."
    
    # Check dependencies
    check_dependencies
    
    # Download and setup SourceMod
    download_sourcemod
    
    # Download essential plugins
    download_plugins
    
    # Compile Nans Surf Plugin
    compile_nans_surf_plugin
    
    # Create Workshop Configuration
    create_workshop_config
    
    log "Nans Surf CS2 Server Setup Complete!"
}

# Execute main setup
main 