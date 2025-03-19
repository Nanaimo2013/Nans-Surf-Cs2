#!/bin/bash

# Create directories if they don't exist
mkdir -p /home/container/game/csgo/maps/workshop

# Download workshop maps using steamcmd
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053395359 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053703590 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053706898 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053712237 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053715412 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053718896 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053722154 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053725698 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053729012 +quit
/home/container/steamcmd/steamcmd.sh +force_install_dir /home/container/game +login anonymous +workshop_download_item 730 3053732456 +quit

echo "Workshop maps downloaded successfully!" 