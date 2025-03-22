# CS2 Surf Server Setup Guide

This guide explains how to set up your Counter-Strike 2 Surf server using the provided gamefiles. The server includes custom configurations, plugins, and resources for a complete surf experience.

## Directory Structure

```
gamefiles/
├── configs/
│   ├── core/              # Core server configurations
│   ├── sourcemod/         # SourceMod-specific configurations
│   ├── core.cfg          # Main server configuration
│   ├── databases.cfg     # Database connection settings
│   ├── maplist.txt       # Server map rotation list
│   ├── required_plugins.txt  # List of required plugins
│   ├── surf_advertisements.cfg # Server advertisement settings
│   └── timer.inc         # Timer system include file
├── data/                 # SourceMod data files
├── materials/            # Custom material files
├── models/              # Custom model files
├── plugins/
│   ├── compiled/        # Compiled .smx plugin files
│   └── source/         # Source .sp plugin files
└── sound/               # Custom sound files

## Installation Instructions

### 1. Server Files Setup

1. Navigate to your CS2 server installation directory:
   ```bash
   cd /path/to/cs2/server
   ```

2. Create the necessary directories if they don't exist:
   ```bash
   mkdir -p game/csgo/addons
   mkdir -p game/csgo/cfg
   ```

### 2. Configuration Files

1. Copy core configurations:
   ```bash
   cp -r gamefiles/configs/core/* game/csgo/cfg/
   ```

2. Copy SourceMod configurations:
   ```bash
   cp -r gamefiles/configs/sourcemod game/csgo/cfg/
   ```

3. Copy main configuration files:
   ```bash
   cp gamefiles/configs/core.cfg game/csgo/cfg/
   cp gamefiles/configs/databases.cfg game/csgo/cfg/
   cp gamefiles/configs/maplist.txt game/csgo/cfg/
   cp gamefiles/configs/surf_advertisements.cfg game/csgo/cfg/
   ```

### 3. Plugins Installation

1. Copy compiled plugins:
   ```bash
   cp -r gamefiles/plugins/compiled/* game/csgo/addons/sourcemod/plugins/
   ```

### 4. Resource Files

1. Copy custom materials:
   ```bash
   cp -r gamefiles/materials/* game/csgo/materials/
   ```

2. Copy custom models:
   ```bash
   cp -r gamefiles/models/* game/csgo/models/
   ```

3. Copy custom sounds:
   ```bash
   cp -r gamefiles/sound/* game/csgo/sound/
   ```

4. Copy data files:
   ```bash
   cp -r gamefiles/data/* game/csgo/addons/sourcemod/data/
   ```

## Configuration Files Guide

### Core Configuration Files

#### 1. server.cfg
Location: `game/csgo/cfg/server.cfg`
```cfg
// Server basic settings
hostname "Your Surf Server Name"
sv_tags "surf,timer"
sv_lan 0
sv_region 3
```
- Basic server settings
- Network configurations
- Server identification
- Performance settings

#### 2. core.cfg
Location: `game/csgo/cfg/core.cfg`
```cfg
// Core settings for SourceMod
"Core"
{
    "Log" { "Enable" "1" }
    "Admins" { "Immunity" "1" }
    "Plugins" { "AutoLoad" "1" }
}
```
- SourceMod core settings
- Plugin management
- Admin system configuration
- Logging settings

#### 3. cs2.cfg
Location: `game/csgo/cfg/cs2.cfg`
```cfg
// CS2-specific settings
sv_airaccelerate 150
sv_maxvelocity 3500
sv_enablebunnyhopping 1
```
- Movement physics
- Game mechanics
- Server-specific CS2 settings

### Surf-Specific Configurations

#### 4. surf.cfg
Location: `game/csgo/cfg/sourcemod/surf.cfg`
```cfg
// Surf gameplay settings
sm_surf_airaccelerate 150
sm_surf_maxspeed 3500
sm_surf_enablestrafeboost 1
```
- Surf movement settings
- Style configurations
- Gameplay mechanics

#### 5. zones.cfg
Location: `game/csgo/addons/sourcemod/data/zones.cfg`
```cfg
"Zones"
{
    "Maps"
    {
        "surf_beginner"
        {
            "Start" {
                "point_a"   "-768 -768 0"
                "point_b"   "768 768 128"
            }
            "End" {
                "point_a"   "-128 -128 -32"
                "point_b"   "128 128 96"
            }
        }
    }
}
```
- Map zone definitions
- Start/end zones
- Bonus zones
- Stage zones

#### 6. timer.cfg
Location: `game/csgo/cfg/sourcemod/timer.cfg`
```cfg
// Timer system configuration
sm_timer_enabled 1
sm_timer_sounds 1
sm_timer_showgains 1
```
- Timer system settings
- Record tracking
- Time display options
- Checkpoint settings

### Database and Storage

#### 7. databases.cfg
Location: `game/csgo/cfg/databases.cfg`
```cfg
"Databases"
{
    "driver_default"     "mysql"
    "surf"
    {
        "driver"         "mysql"
        "host"          "localhost"
        "database"      "surf_stats"
        "user"          "username"
        "pass"          "password"
    }
}
```
- Database connections
- Storage settings
- Credentials configuration

#### 8. storage.cfg
Location: `game/csgo/cfg/sourcemod/storage.cfg`
```cfg
"Storage"
{
    "driver"    "sql"
    "database"  "surf"
}
```
- Data storage configuration
- Record keeping settings
- Backup configurations

### Interface and Display

#### 9. hud.cfg
Location: `game/csgo/cfg/sourcemod/hud.cfg`
```cfg
// HUD display settings
sm_timer_hud_enabled 1
sm_timer_hud_position "0.05 0.05"
```
- HUD positioning
- Display elements
- Color settings
- Visibility options

#### 10. quickmenu.cfg
Location: `game/csgo/cfg/sourcemod/quickmenu.cfg`
```cfg
// Quick menu configuration
sm_quickmenu_enabled 1
sm_quickmenu_title "Surf Menu"
```
- Menu structure
- Command shortcuts
- Menu options

### Administrative Tools

#### 11. admin_commands.cfg
Location: `game/csgo/cfg/sourcemod/admin_commands.cfg`
```cfg
// Admin command settings
sm_admin_commands_enabled 1
sm_admin_level_zoneedit 1
```
- Admin command access
- Permission levels
- Command restrictions

### Server Communication

#### 12. surf_advertisements.cfg
Location: `game/csgo/cfg/surf_advertisements.cfg`
```cfg
"Advertisements"
{
    "1" {
        "text" "{green}[Surf] {default}Type !help for commands"
        "chat" "1"
    }
    "2" {
        "text" "{green}[Surf] {default}Current Map: {olive}%currentmap%"
        "chat" "1"
    }
}
```
- Advertisement messages
- Rotation settings
- Display locations
- Message formatting

### Map Management

#### 13. maplist.txt
Location: `game/csgo/cfg/maplist.txt`
```txt
surf_beginner
surf_easy
surf_medium
surf_advanced
```
- Available maps
- Map rotation
- Workshop IDs
- Map categories

## Configuration Tips

1. **Order of Loading**
   - Load core configs first
   - Then surf-specific configs
   - Finally, plugin configs

2. **Performance Optimization**
   - Adjust tickrate settings
   - Configure network settings
   - Optimize memory usage

3. **Security Considerations**
   - Secure RCON password
   - Configure admin access
   - Set up backup systems

4. **Custom Settings**
   - Modify values based on server capacity
   - Adjust for community preferences
   - Balance difficulty settings

## Required Plugins

The server requires several plugins for full functionality:

1. Timer System
2. Surf Stats
3. Movement Modifications
4. Admin Tools

Check `required_plugins.txt` for a complete list of required plugins.

## Post-Installation

1. Verify file permissions:
   ```bash
   chmod -R 755 game/csgo/addons
   chmod -R 755 game/csgo/cfg
   ```

2. Start the server using the provided startup command in the egg configuration.

3. Check the server console for any error messages.

4. Connect to the server and verify that all plugins are loaded correctly using:
   ```
   sm plugins list
   ```

## Troubleshooting

### Common Issues

1. **Plugin Load Failures**
   - Check plugin dependencies
   - Verify file permissions
   - Check SourceMod error logs

2. **Map Load Failures**
   - Ensure workshop maps are downloaded
   - Verify map file permissions
   - Check map dependencies

3. **Database Connection Issues**
   - Verify database credentials
   - Check network connectivity
   - Ensure database structure is correct

## Support

For additional support or bug reports, please create an issue in the repository.

## License

This server configuration is provided under the MIT License. See LICENSE file for details. 