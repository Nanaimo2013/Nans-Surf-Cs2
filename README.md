# Nans Surf CS2 Server Setup

## Overview
This repository contains a comprehensive setup for a CS2 Surf server with custom configurations, plugins, and map collections.

## Prerequisites
- Linux-based server (recommended)
- CS2 Dedicated Server
- Steam Game Server Account

## Installation

### Automatic Installation
```bash
# Clone the repository
git clone https://github.com/Nanaimo2013/Nans-Surf-Cs2.git
cd Nans-Surf-Cs2

# Make setup script executable
chmod +x scripts/setup_surf_server.sh

# Run the setup script
./scripts/setup_surf_server.sh
```

### Manual Installation Steps
1. Download SourceMod for CS2
2. Install required plugins
3. Compile custom plugins
4. Configure server settings

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