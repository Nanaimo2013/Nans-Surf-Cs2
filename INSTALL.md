# Porter's Surf Server Installation Guide

## Prerequisites

1. **Server Requirements**
   - Counter-Strike 2 Dedicated Server
   - MySQL Server (5.7+ or MariaDB 10.2+)
   - SourceMod and MetaMod
   - 2GB+ RAM
   - 10GB+ Storage

2. **Required Plugins**
   - SourceMod and MetaMod
   - MultiColors
   - MapChooser Extended
   - MovementAPI
   - DHooks
   - SurfTimer

## Installation Steps

1. **Automated Installation**
   ```bash
   # Make the script executable
   chmod +x install_surf.sh
   
   # Run the installation script
   ./install_surf.sh
   ```

2. **Manual Configuration**
   - Configure MySQL database in `addons/sourcemod/configs/databases.cfg`:
   ```cfg
   "porter_surf"
   {
       "driver"      "mysql"
       "host"        "localhost"
       "database"    "porter_surf"
       "user"        "your_username"
       "pass"        "your_password"
   }
   ```

3. **Admin Setup**
   - Edit `addons/sourcemod/configs/admins_simple.ini`:
   ```
   "STEAM_1:X:XXXXXXXX" "99:z" // Your Name
   ```
   - Flag meanings:
     - z: Root (all permissions)
     - b: Basic admin
     - c: Kick/ban
     - d: Map control
     - e: Server settings
     - m: Custom flags

## Directory Structure

```
📁 csgo/
  📁 addons/
    📁 sourcemod/
      📁 configs/
        📁 surf/           # Surf configuration files
          📄 hud.cfg       # HUD settings
          📄 quickmenu.cfg # Quick menu configuration
          📄 storage.cfg   # Data storage settings
        📄 advertisements.cfg
        📄 admins_simple.ini
      📁 plugins/
        📄 nans_surf.smx   # Main plugin
      📁 data/
        📁 surf/           # Statistics storage
  📁 cfg/
    📄 server.cfg         # Server configuration
    📁 sourcemod/
      📁 surf/
        📄 maplist.txt    # Surf map list
  📁 maps/               # Surf maps directory
```

## Configuration Files

1. **server.cfg**
   - Basic server settings
   - Surf physics configuration
   - Round/match settings
   - Player settings

2. **hud.cfg**
   - Speed display settings
   - Timer display
   - Rank display
   - Style display

3. **advertisements.cfg**
   - Server messages
   - Timer announcements
   - Player achievements

4. **quickmenu.cfg**
   - Player quick commands
   - Admin quick commands
   - Information commands

## Player Commands

### Basic Commands
- `!r` or `!restart` - Respawn at start
- `!cp` - Set checkpoint
- `!tp` - Teleport to checkpoint
- `!style` - Change surf style
- `!top` - View leaderboard
- `!rank` - Show your rank
- `!rtv` - Vote to change map
- `!hide` - Toggle player visibility

### Admin Commands
- `!admin` - Open admin menu
- `!settier` - Set map tier
- `!zones` - Edit map zones
- `!resetmap` - Reset map records
- `!maplist` - Edit map rotation

## Map Installation

### Method 1: FastDL (Recommended)
1. Visit [GameBanana CS2 Surf Maps](https://gamebanana.com/games/8010)
2. Download desired maps (`.bsp` files)
3. Upload to your server's `maps/` directory
4. Add map names to `cfg/sourcemod/surf/maplist.txt`

### Method 2: Automated Installation
The `install_surf.sh` script includes popular surf maps:
```bash
./install_surf.sh --maps-only  # Only install maps
```

### Method 3: Workshop Collection
1. Create a workshop collection
2. Add surf maps to your collection
3. Set workshop collection ID in server.cfg:
```cfg
host_workshop_collection "YOUR_COLLECTION_ID"
```

### Popular Starter Maps
- surf_beginner
- surf_utopia
- surf_mesa
- surf_kitsune
- surf_beginner2
- surf_easy_v2
- surf_rookie
- surf_japan_ptad
- surf_summer

### Map Tiers
Maps are categorized by difficulty (Tier 1-6):
- Tier 1: Beginner (surf_beginner, surf_easy)
- Tier 2: Easy (surf_mesa, surf_utopia)
- Tier 3: Medium (surf_kitsune, surf_summer)
- Tier 4: Hard (surf_catalyst, surf_ace)
- Tier 5: Expert (surf_rebel, surf_network)
- Tier 6: Elite (surf_forbidden_ways, surf_nightmare)

To set a map's tier:
```
!settier <map> <tier>
```

## Troubleshooting

1. **Plugin Loading Issues**
   - Check SourceMod error logs
   - Verify file permissions (CHMOD 755 for directories, 644 for files)
   - Ensure all dependencies are installed

2. **Map Issues**
   - Verify map file permissions
   - Check maplist.txt entries
   - Look for missing resources

3. **Database Issues**
   - Check MySQL connection settings
   - Verify database permissions
   - Look for table creation errors

4. **Performance Issues**
   - Monitor server resource usage
   - Check network connectivity
   - Verify tickrate settings

## Support

For support:
- Contact: Nanaimo_2013
- Discord: [JmfHosting Support]
- Twitch: twitch.tv/porterdub 