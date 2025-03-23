@echo off
echo Installing CS2 Dedicated Server...

:: Create game directory if it doesn't exist
mkdir game 2>nul

:: Run SteamCMD to install CS2
steamcmd\steamcmd.exe +force_install_dir "%cd%\game" +login anonymous +app_update 730 validate +quit

:: Create necessary directories
mkdir "game\csgo\cfg" 2>nul
mkdir "game\csgo\addons\sourcemod\plugins" 2>nul
mkdir "game\csgo\addons\sourcemod\configs" 2>nul
mkdir "game\csgo\addons\sourcemod\data" 2>nul

:: Download MetaMod and SourceMod
powershell -Command "Invoke-WebRequest -Uri 'https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-windows.zip' -OutFile 'metamod.zip'"
powershell -Command "Invoke-WebRequest -Uri 'https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6934-windows.zip' -OutFile 'sourcemod.zip'"

:: Extract MetaMod and SourceMod
powershell -Command "Expand-Archive -Path 'metamod.zip' -DestinationPath 'game\csgo' -Force"
powershell -Command "Expand-Archive -Path 'sourcemod.zip' -DestinationPath 'game\csgo' -Force"

:: Clean up downloaded files
del metamod.zip
del sourcemod.zip

echo Installation completed! 