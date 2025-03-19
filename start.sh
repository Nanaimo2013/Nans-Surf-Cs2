#!/bin/bash

# Create the container user and group if they don't exist
groupadd -g 999 container
useradd -u 999 -g container -d /home/container container

# Create necessary directories
mkdir -p /home/container/game/csgo/maps/workshop
mkdir -p /home/container/cfg
mkdir -p /home/container/.steam/sdk64

# Set proper permissions
chmod -R 755 /home/container
chown -R container:container /home/container

# Download and extract SteamCMD if not present
if [ ! -f "/home/container/steamcmd/steamcmd.sh" ]; then
    mkdir -p /home/container/steamcmd
    cd /home/container/steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
fi

# Make steamcmd.sh executable
chmod +x /home/container/steamcmd/steamcmd.sh

# Install/Update CS2 server
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +app_update 730 +quit"

# Download workshop maps
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053395359 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053703590 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053706898 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053712237 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053715412 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053718896 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053722154 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053725698 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053729012 +quit"
su container -c "/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053732456 +quit"

# Create symlink for steamclient.so
ln -sf /home/container/.steam/sdk64/steamclient.so /home/container/game/bin/linuxsteamrt64/steamclient.so

# Start the CS2 server as container user
cd /home/container/game
su container -c "./cs2.sh -dedicated -console -usercon +ip 0.0.0.0 -port 25566 +map surf_beginner -maxplayers 64 +sv_setsteamaccount 7912CB397FC178ACF5E752CA6B4D75A3 +exec server.cfg +exec workshop_maps.cfg +sv_workshop_allow_other_maps 1" 