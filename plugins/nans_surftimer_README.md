# Nans Surf Timer Plugin

## Overview
A comprehensive, custom-built surf timer plugin for CS2 designed to provide an advanced timing and tracking system for surf servers.

## Features
- Robust timer tracking
- Multiple surf styles support
- Checkpoint system
- Database integration for personal and server records
- Top times tracking

## Commands
- `!timer` - Show current timer status
- `!checkpoint` - Save a checkpoint
- `!teleport` - Teleport to last checkpoint
- `!restart` - Restart your run
- `!top` - Show top times for the current map

## Surf Styles Supported
- Normal
- Sideways
- Backwards
- Half Sideways
- Auto Bhop
- Scroll

## Database Integration
The plugin uses a MySQL database to store:
- Player times
- Map records
- Personal bests

## Installation
1. Compile the plugin using SourceMod compiler
2. Place `nans_surftimer.smx` in `addons/sourcemod/plugins/`
3. Configure database settings in `databases.cfg`

## Configuration
Customize the plugin by modifying ConVars and database settings.

## Requirements
- SourceMod 1.11+
- CS2 Game Server
- MySQL Database (optional)

## Troubleshooting
- Ensure database connection is properly configured
- Check SourceMod logs for any errors
- Verify plugin compatibility with CS2

## Contributing
Contributions are welcome! Please submit pull requests or open issues on the GitHub repository.

## License
[Specify your license here]

## Author
Nanaimo_2013 