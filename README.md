# DCS World Overlay

A real-time overlay for DCS World that displays aircraft weapons, fuel status, and flight information.

## Features

- **Aircraft Information**: Shows current aircraft with icon
- **Weapons Display**: Air-to-Air and Air-to-Ground weapons with counts
- **Fuel Status**: Visual fuel bar with remaining fuel and estimated time
- **Automatic Installation**: Installer handles Export.lua setup automatically

## Quick Start (For Users)

### Download & Install

1. Go to [Releases](../../releases)
2. Download `DCS-Overlay-Setup-v1.0.0.exe`
3. Run the installer
4. Follow the setup wizard (it will auto-detect your DCS installation)
5. Done!

The installer will:
- Detect your DCS Saved Games folder automatically
- Install Export.lua (preserves existing exports like SRS, TacView)
- Create Start Menu and Desktop shortcuts
- Set up everything needed to run

### Running the Overlay

1. **Launch DCS Overlay** from Start Menu or Desktop
2. Browser opens automatically with the overlay
3. **Start DCS World** and enter any mission
4. Overlay updates automatically with your aircraft data

## System Requirements

- Windows 10/11 (64-bit)
- DCS World (any version)
- Modern web browser (Chrome, Firefox, Edge)

## Compatibility

The overlay is fully compatible with other DCS export mods:
- ✅ DCS-SRS (SimpleRadio)
- ✅ TacView
- ✅ Other Export.lua scripts

The installer appends to your existing Export.lua instead of replacing it.

## Usage

- **Left Panel**: Weapons loadout organized by type (A/A and A/G)
- **Fuel Display**: Visual bar showing remaining fuel percentage and weight
- **Aircraft Name**: Current aircraft displayed at top

## Troubleshooting

### Windows Security Warning
- Click "More info" → "Run anyway"
- This is normal for unsigned executables
- You can add to Windows Defender exceptions

### "Connecting to DCS..." stays on screen
- Ensure DCS is running with an aircraft loaded
- Check that Export.lua was installed: `C:\Users\[YourUsername]\Saved Games\DCS\Scripts\Export.lua`
- Look for "DCS-OVERLAY" text in Export.lua to verify installation

### No weapons showing
- Load weapons in mission editor
- Verify aircraft has pylons/hardpoints loaded
- Check browser console (F12) for errors

### Overlay not updating
- Refresh browser (F5)
- Restart DCS Overlay application
- Check DCS logs in `Saved Games\DCS\Logs\` for export errors

### Port conflicts
- Close applications using ports 3000, 8080, or 12340
- Common conflicts: other overlays, web servers, development tools

## Development

### Prerequisites

- Node.js (v14 or higher)
- npm
- Inno Setup (for building installer)

### Setup

```bash
git clone https://github.com/Dillen198/DCS-OVERLAYER.git
cd DCS-OVERLAYER
npm install
```

### Development Mode

```bash
npm start
```

Opens overlay at `http://localhost:3000`

### Building

```bash
# Build executable and assets
npm run build

# Create installer (requires Inno Setup)
npm run package:win
```

Output:
- `dist/DCS-Overlay.exe` - Standalone executable
- `release/DCS-Overlay-Setup-v1.0.0.exe` - Windows installer

## Project Structure

```
dcs-overlay/
├── installer.js            # Main application with auto-installer
├── build.js               # Build script
├── package.js             # Installer packaging script
├── Export.lua             # DCS export script
├── overlay.html           # Web UI
├── installer.iss          # Inno Setup configuration
├── package.json           # Dependencies
├── mappings/
│   ├── aircraft.json      # Aircraft icon mappings
│   └── weapons.json       # Weapon icon mappings
└── images/
    ├── aircraft/          # Aircraft icons
    └── weapons/           # Weapon icons
```

## Customization

### Update Rate

In `Export.lua`:
```lua
local UPDATE_INTERVAL = 0.1  -- seconds
```

### Overlay Position

In `overlay.html`:
```css
.overlay-container {
    left: 10px;
    bottom: 10px;
}
```

### Server Ports

In `installer.js`:
```javascript
const UDP_PORT = 12340;
const WS_PORT = 8080;
const HTTP_PORT = 3000;
```

## Technical Details

**Architecture:**
- Export Script: Runs in DCS, writes JSON to temp file
- Bridge Server: Node.js app reads JSON, serves via WebSocket
- Web UI: HTML/CSS/JS displays real-time data

**Data Flow:**
```
DCS → Export.lua → JSON file → Bridge Server → WebSocket → Browser
```

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see LICENSE.txt

## Credits

Built for DCS World using the official DCS export API.

## Support

- **Issues**: [GitHub Issues](https://github.com/Dillen198/DCS-OVERLAYER/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Dillen198/DCS-OVERLAYER/discussions)
- **Discord**: [Join our Discord server](https://discord.gg/SuTqTaFR7T)

## Changelog

### v1.0.0 (2025-09-29)
- Initial release
- Auto-installer with DCS detection
- Real-time weapons and fuel display
- Support for all DCS aircraft
- Compatible with existing export mods
