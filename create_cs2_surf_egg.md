# Counter-Strike 2 Surf Egg Configuration

## Basic Information
- **Name**: Counter-Strike 2 Surf
- **Description**: Counter-Strike 2 Surf Server with custom map rotations, SourceMod plugins, and surf-specific configurations.

## Docker Images
- SteamRT3: `ghcr.io/1zc/steamrt3-pterodactyl:latest`
- SteamRT3-PublicBeta: `ghcr.io/1zc/steamrt3-pterodactyl:beta-latest`
- SteamRT3-Dev: `ghcr.io/1zc/steamrt3-pterodactyl:dev`
- SteamRT3-PublicBetaDev: `ghcr.io/1zc/steamrt3-pterodactyl:beta-dev`

## Startup Command
```bash
bash install_surf.sh && ./game/cs2.sh -dedicated +ip 0.0.0.0 -port {{SERVER_PORT}} +map {{SRCDS_MAP}} -maxplayers {{SRCDS_MAXPLAYERS}} +sv_setsteamaccount {{STEAM_ACC}} +exec server.cfg +exec workshop_maps.cfg {{CUSTOM_STARTUP_ARGS}}
```

## Process Management
- **Stop Command**: `quit`

## Configuration Files
```json
{
    "files": "{}",
    "startup": {
        "done": "Connection to Steam servers successful"
    },
    "logs": "{}",
    "stop": "quit"
}
```

## Installation Script
```bash
#!/bin/bash
# Surf Server Installation Script

apt -y update
apt -y --no-install-recommends install curl lib32gcc-s1 ca-certificates

cd /tmp
curl -sSL -o steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz

mkdir -p /mnt/server/steam
tar -xzvf steamcmd.tar.gz -C /mnt/server/steam
cd /mnt/server/steam

chown -R root:root /mnt

export HOME=/mnt/server

./steamcmd.sh +login anonymous +force_install_dir /mnt/server +app_update 730 +quit

mkdir -p /mnt/server/game/csgo
echo "LD_LIBRARY_PATH=./bin:LD_LIBRARY_PATH ./bin/linuxsteamrt64/cs2" > /mnt/server/game/cs2.sh
chmod +x /mnt/server/game/cs2.sh

cp /mnt/server/install_surf.sh /mnt/server/
chmod +x /mnt/server/install_surf.sh

cp /mnt/server/pterodactyl-startup.sh /mnt/server/
chmod +x /mnt/server/pterodactyl-startup.sh
```

## Variables Detailed Explanation

### 1. Surf Map
- **Name**: Surf Map
- **Description**: The default surf map for the server.
- **Environment Variable**: `SRCDS_MAP`
- **Default Value**: `surf_beginner`
- **Purpose**: Automatically sets the starting map when the server launches
- **Validation**: 
  ```
  required|string|alpha_dash
  ```

### 2. Server Name
- **Name**: Server Name
- **Description**: The name of your surf server
- **Environment Variable**: `SERVER_NAME`
- **Default Value**: `Nans Surf CS2 Serve`
- **Purpose**: Identifies your server in server browsers and player lists
- **Validation**: 
  ```
  required|string|max:64
  ```

### 3. Steam Account Token
- **Name**: Steam Account Token
- **Description**: Your Steam Game Server Account token
- **Environment Variable**: `STEAM_ACC`
- **Default Value**: `(empty)`
- **Purpose**: Authenticates and registers your game server with Steam
- **Obtain**: https://steamcommunity.com/dev/managegameservers
- **Validation**: 
  ```
  required|string|max:32
  ```

### 4. Source AppID
- **Name**: Source AppID
- **Description**: NOT VISIBLE TO USERS. DO NOT EDIT.
- **Environment Variable**: `SRCDS_APPID`
- **Default Value**: `730`
- **Purpose**: Identifies the specific game application for Steam
- **Validation**: 
  ```
  required|numericr
  ```

### 5. Max Players
- **Name**: Max Players
- **Description**: The maximum number of players the surf server can host
- **Environment Variable**: `SRCDS_MAXPLAYERS`
- **Default Value**: `32`
- **Purpose**: Controls server capacity and player limit
- **Validation**: 
  ```
  required|numeric
  ```

### 6. Server Tier
- **Name**: Server Tier
- **Description**: Select the primary surf map tier for this server (1-5)
- **Environment Variable**: `SURF_TIER`
- **Default Value**: `1`
- **Purpose**: Defines the difficulty level of surf maps on the server
- **Validation**: 
  ```
  required|numeric|between:1,5
  ```
- **Tier Options**:
  ```
  1: Tier 1 - Beginner
  2: Tier 2 - Easy
  3: Tier 3 - Medium
  4: Tier 4 - Hard
  5: Tier 5 - Expert
  ```

### 7. Disable Updates
- **Name**: Disable Updates
- **Description**: Set to 1 to stop updates
- **Environment Variable**: `SRCDS_STOP_UPDATE`
- **Default Value**: `0`
- **Purpose**: Prevents automatic game server updates
- **Validation**: 
  ```
  required|numeric
  ```

### 8. Validate Install
- **Name**: Validate Install
- **Description**: Toggles SteamCMD validation of game server files
- **Environment Variable**: `SRCDS_VALIDATE`
- **Default Value**: `0`
- **Purpose**: Ensures integrity of game server installation files
- **Validation**: 
  ```
  required|numeric
  ```

### 9. Custom Startup Arguments
- **Name**: Custom Startup Arguments
- **Description**: Additional custom arguments to pass to the server startup command
- **Environment Variable**: `CUSTOM_STARTUP_ARGS`
- **Default Value**: `(empty)`
- **Purpose**: Allows additional customization of server launch parameters
- **Validation**: 
  ```
  nullable|string|max:255
  ```

## Additional Notes
- Requires Steam Game Server Account Token
- Supports custom map rotations
- Includes SourceMod plugins
- Surf-specific configurations