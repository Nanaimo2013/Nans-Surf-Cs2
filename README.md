# Nans Surf CS2 Server Plugin

## Plugin Structure

### Core Plugins
- `nans_surf.sp`: Main server plugin
- `nans_surftimer/`
  - `database.sp`: Database handling
  - `player_manager.sp`: Player statistics and rank management
  - `leaderboard.sp`: Leaderboard and ranking system
  - `replay_system.sp`: Replay recording and playback
  - `map_manager.sp`: Map and stage management
  - `zones.sp`: Zone detection and management

## Installation

### Prerequisites
- CS2 Server
- SourceMod 1.11+
- Steam Game Server Account

### Quick Install
1. Run the `install_surf.sh` script
2. Configure environment variables
3. Start the server

### Environment Variables
- `STEAM_ACCOUNT`: Required Steam Game Server Token
- `SERVER_PORT`: Server port (default: 27015)
- `SRCDS_MAP`: Starting map (default: surf_beginner)
- `SRCDS_MAXPLAYERS`: Max players (default: 32)

## Configuration

### Server Configuration
Edit files in `csgo/cfg/sourcemod/surf/`:
- `server.cfg`: Server settings
- `workshop_maps.cfg`: Workshop map configuration
- `admin_commands.cfg`: Admin command settings

## Commands

### Player Commands
- `!r`: Restart run
- `!re`: Repeat stage
- `!st`: Stuck/Restart
- `!cp`: Set checkpoint
- `!tp`: Teleport to checkpoint

### Admin Commands
- `!zones`: Manage map zones
- `!settier`: Set map tier
- `!resetmap`: Reset map records

## Support
Report issues on GitHub repository.

## Server Features
- Multiple surf map tiers (Beginner to Expert)
- Custom surf timer plugin
- Advanced ranking system
- Map voting and nomination
- Admin management tools

## Map Tiers
- Tier 1 (Beginner): Easy maps for new players
- Tier 2 (Easy): Slightly more challenging maps
- Tier 3 (Medium): Intermediate difficulty
- Tier 4 (Hard): Advanced maps
- Tier 5 (Expert): Extremely challenging maps

## Workshop Collection
The server uses a custom workshop collection with carefully curated surf maps.

## Configuration Files
- `cfg/server.cfg`: Main server configuration
- `cfg/workshop_maps.cfg`: Workshop map collection
- `addons/sourcemod/configs/`: Various plugin configurations

## Troubleshooting
- Ensure all dependencies are installed
- Check server logs for any errors
- Verify Steam Game Server Account is correctly set up

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
[Specify your license here]

## Credits
- Developed by Nanaimo_2013
- Special thanks to the CS2 and SourceMod communities 