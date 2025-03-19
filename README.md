# Nans Surf CS2 Server

A feature-rich Counter-Strike 2 surf server with speed overlay, leaderboard functionality, and comprehensive player statistics.

## Features

- **Advanced Timer System**
  - Accurate timing and speed tracking
  - Multi-stage support
  - Checkpoint system
  - Personal best tracking
  - World record tracking

- **Player Statistics**
  - Global rankings
  - Map-specific rankings
  - Style-specific rankings
  - Points system
  - Awards and achievements

- **HUD Features**
  - Dynamic speed display
  - Sync percentage
  - Strafe counter
  - Stage progress
  - Time comparison (WR/PB)
  - Key display
  - Velocity meter

- **Server Features**
  - Multiple surf styles
  - Custom advertisements
  - Map voting system (RTV)
  - Admin commands
  - Troll commands
  - VIP system

## Requirements

- Counter-Strike 2 Dedicated Server
- SourceMod and Metamod for CS2
- MySQL Database
- Web server for overlay (optional)

## Quick Start

1. Run the installation script:
```bash
chmod +x install_surf.sh
./install_surf.sh
```

2. Configure your admin access in `addons/sourcemod/configs/admins_simple.ini`
3. Start the server
4. Access the admin menu with `!admin` in chat

## Directory Structure

```
├── addons/
│   ├── sourcemod/
│   │   ├── configs/
│   │   │   ├── surf/           # Surf configurations
│   │   │   ├── admins_simple.ini
│   │   │   └── advertisements.cfg
│   │   ├── plugins/
│   │   │   └── nans_surf.smx   # Main plugin
│   │   └── data/
│   │       └── surf/           # Statistics storage
├── cfg/
│   ├── server.cfg
│   └── sourcemod/
│       └── surf/
│           └── maplist.txt
└── maps/                      # Surf maps
```

## Player Commands

- `!surf` - Open surf menu
- `!r` - Restart run
- `!cp` - Set checkpoint
- `!tp` - Teleport to checkpoint
- `!style` - Change surf style
- `!top` - View leaderboard
- `!rank` - Show your rank
- `!rtv` - Vote to change map
- `!hide` - Toggle player visibility

## Credits

Created by Nans & Nanaimo_2013
Hosted by JmfHosting 