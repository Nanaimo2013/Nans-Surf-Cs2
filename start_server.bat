@echo off
echo Starting CS2 Surf Server...

cd game
start cs2.exe -dedicated -console -usercon +ip 0.0.0.0 -port 25566 +map surf_beginner -maxplayers 64 +sv_setsteamaccount 7912CB397FC178ACF5E752CA6B4D75A3 +exec server.cfg +exec workshop_maps.cfg +sv_workshop_allow_other_maps 1

echo Server started! Press Ctrl+C to stop the server.
pause 