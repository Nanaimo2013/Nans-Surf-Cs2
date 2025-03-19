#!/bin/bash

echo "★ Starting Nans Surf CS2 Server ★"

# Install surf maps and plugins if needed
if [ ! -f "/home/container/game/csgo/maps/surf_beginner.bsp" ]; then
    echo "Surf maps not found! Running installation script first..."
    bash /home/container/install_surf.sh
    echo "Installation complete, starting server..."
fi

# Start CS2 with surf map
/home/container/game/cs2.sh -dedicated \
    +ip 0.0.0.0 \
    -port 25566 \
    +map surf_beginner \
    -maxplayers 32 \
    +sv_setsteamaccount "$STEAM_ACCOUNT" \
    +exec server.cfg \
    +exec workshop_maps.cfg 