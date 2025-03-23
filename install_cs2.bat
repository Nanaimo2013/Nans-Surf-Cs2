@echo off
echo Installing CS2 Dedicated Server...

:: Create directories
mkdir steamcmd 2>nul
mkdir game 2>nul

:: Download SteamCMD if not exists
if not exist "steamcmd\steamcmd.exe" (
    echo Downloading SteamCMD...
    powershell -Command "Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile 'steamcmd.zip'"
    powershell -Command "Expand-Archive -Path 'steamcmd.zip' -DestinationPath 'steamcmd' -Force"
    del steamcmd.zip
)

:: Run SteamCMD to install CS2
echo Installing CS2 Dedicated Server...
steamcmd\steamcmd.exe +force_install_dir "%cd%\game" +login anonymous +app_update 730 +app_update 2403830 validate +quit

:: Create necessary directories
mkdir "game\game\csgo" 2>nul
mkdir "game\game\csgo\cfg" 2>nul
mkdir "game\game\csgo\addons" 2>nul

:: Download latest MetaMod:Source for CS2
echo Downloading MetaMod:Source for CS2...
powershell -Command "Invoke-WebRequest -Uri 'https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1200-windows.zip' -OutFile 'metamod.zip'"

:: Download latest SourceMod for CS2
echo Downloading SourceMod for CS2...
powershell -Command "Invoke-WebRequest -Uri 'https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git1234-windows.zip' -OutFile 'sourcemod.zip'"

:: Extract MetaMod and SourceMod
echo Extracting MetaMod and SourceMod...
powershell -Command "Expand-Archive -Path 'metamod.zip' -DestinationPath 'game\game\csgo' -Force"
powershell -Command "Expand-Archive -Path 'sourcemod.zip' -DestinationPath 'game\game\csgo' -Force"

:: Copy configuration files
echo Copying configuration files...
xcopy /Y /E "gamefiles\configs\*" "game\game\csgo\addons\sourcemod\configs\"
xcopy /Y /E "gamefiles\plugins\*" "game\game\csgo\addons\sourcemod\plugins\"

:: Clean up downloaded files
del metamod.zip
del sourcemod.zip

:: Create server.cfg
echo Creating server configuration...
(
echo hostname "Nans Surf Server [CS2] - Local Test"
echo sv_lan 1
echo sv_cheats 1
echo mp_autoteambalance 0
echo mp_limitteams 0
echo sv_allowupload 1
echo sv_allowdownload 1
echo sv_maxrate 0
echo sv_minrate 100000
echo sv_maxcmdrate 128
echo sv_mincmdrate 128
echo sv_maxupdaterate 128
echo sv_minupdaterate 128
echo sv_accelerate 10
echo sv_airaccelerate 150
echo sv_wateraccelerate 10
echo sv_maxvelocity 3500
) > "game\game\csgo\cfg\server.cfg"

:: Create start server batch file
echo Creating start server script...
(
echo @echo off
echo echo Starting CS2 Server...
echo cd game
echo start game\cs2.exe -dedicated -console -game csgo +map surf_beginner +exec server.cfg
) > "start_server.bat"

echo Installation completed! 
echo To start the server, run start_server.bat
pause 