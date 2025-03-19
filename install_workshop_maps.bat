@echo off
echo Installing workshop maps...

REM Create directories if they don't exist
mkdir "game\csgo\maps\workshop" 2>nul

REM Download workshop maps using steamcmd
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053395359 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053703590 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053706898 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053712237 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053715412 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053718896 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053722154 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053725698 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053729012 +quit
steamcmd\steamcmd.exe +force_install_dir "%CD%\game" +login anonymous +workshop_download_item 730 3053732456 +quit

echo Workshop maps downloaded successfully!
pause 