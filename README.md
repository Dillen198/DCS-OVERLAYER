# DCS World Overlay

Professional broadcast overlay for DCS World streamers, displaying real-time aircraft weapons, fuel status, and flight information to enhance viewer experience.

## Overview

DCS Overlay is a broadcaster-focused tool designed for content creators streaming DCS World. It provides viewers with clear, real-time information about your aircraft's loadout and fuel state through a clean, customizable web interface.

**Perfect for:**
- Live streaming on Twitch, YouTube, Discord
- Recording DCS gameplay content
- Squadron training sessions
- Multiplayer operations with spectators

## Key Features

### Real-Time Data Display
- **Weapons Loadout**: Organized Air-to-Air and Air-to-Ground inventory with live counts
- **Fuel Management**: Visual gauge displaying percentage, weight (kg), and estimated time remaining
- **Aircraft Identification**: Clear display of current aircraft module
- **Live Updates**: 10Hz refresh rate for smooth, responsive data

### Broadcaster-Friendly Design
- **Browser Source Compatible**: Works seamlessly with OBS Studio, Streamlabs, XSplit
- **Customizable Position**: Place overlay anywhere on screen via CSS
- **Transparent Background**: Integrates naturally with streaming layouts
- **Clean Visual Design**: Professional appearance suitable for broadcast quality

### Automatic Installation
- **One-Click Setup**: Professional installer with setup wizard
- **Smart DCS Detection**: Automatically locates your DCS installation
- **Non-Destructive Installation**: Preserves existing Export.lua configurations
- **Multi-Mod Compatible**: Works alongside DCS-SRS, TacView, and other export tools

## Installation

### For Streamers & Content Creators

1. **Download** the latest installer from [Releases](../../releases)
   - File: `DCS-Overlay-Setup-v1.0.0.exe`

2. **Run the Installer**
   - Follow the setup wizard
   - Installer auto-detects DCS Saved Games location
   - Creates desktop and Start Menu shortcuts

3. **Launch the Overlay**
   - Start DCS Overlay from shortcuts
   - Browser opens automatically at `http://localhost:3000`
   - Add as Browser Source in OBS/streaming software

4. **Configure for Streaming** (OBS Studio example)
   - Add Browser Source
   - URL: `http://localhost:3000`
   - Width: 1920, Height: 1080
   - Check "Shutdown source when not visible"
   - Position and scale as desired

## System Requirements

- **Operating System**: Windows 10/11 (64-bit)
- **DCS World**: Any version (Stable, Open Beta, or Server)
- **Browser**: Chrome, Firefox, Edge, or modern browser
- **Streaming Software**: OBS Studio, Streamlabs OBS, XSplit (recommended)
- **Network Ports**: 3000, 8080, 12340 (locally accessible only)

## Compatibility

**Verified Compatible Export Tools:**
- DCS-SRS (SimpleRadio Standalone)
- TacView Advanced
- Lotatc
- Other Export.lua based tools

The installer intelligently appends to existing Export.lua files, creating backups and preserving all existing functionality.

## Streaming Setup Guide

### OBS Studio Integration

1. Launch DCS Overlay application
2. In OBS, add **Browser Source**:
   - **URL**: `http://localhost:3000`
   - **Width**: 1920
   - **Height**: 1080
   - **Custom CSS**: (optional, for positioning)
3. Position overlay on stream layout
4. Start DCS World - data flows automatically

### Customization for Streaming

**Overlay Position** (edit `overlay.html`):
```css
.overlay-container {
    left: 20px;      /* Distance from left edge */
    bottom: 20px;    /* Distance from bottom edge */
}
```

**Opacity/Transparency**:
```css
.overlay-container {
    opacity: 0.9;    /* 0.0 to 1.0 */
}
```

**Update Rate** (edit `Export.lua`):
```lua
local UPDATE_INTERVAL = 0.1  -- Update every 0.1 seconds (10Hz)
```

## Troubleshooting

### Stream-Specific Issues

**Overlay not visible in OBS:**
- Verify DCS Overlay application is running
- Check Browser Source URL is exactly `http://localhost:3000`
- Ensure DCS is running with an aircraft loaded
- Refresh the Browser Source in OBS

**Data not updating during stream:**
- Confirm Export.lua is installed in DCS Scripts folder
- Restart both DCS and DCS Overlay application
- Check DCS logs: `Saved Games\DCS\Logs\dcs.log` for "DCS-OVERLAY" entries

**Performance impact on stream:**
- Overlay uses minimal resources (<1% CPU, <50MB RAM)
- Browser source refresh rate: match to stream FPS
- Consider disabling when not actively flying

### General Issues

**Windows Security Warning:**
- Click "More info" → "Run anyway"
- Unsigned executables trigger standard Windows protection
- Add to Windows Defender exclusions if desired

**Port Conflicts:**
- Default ports: 3000 (HTTP), 8080 (WebSocket), 12340 (UDP)
- Close conflicting applications or modify ports in `installer.js`
- Common conflicts: local web servers, development tools

**Export.lua Installation:**
- Installer creates backups: `Export.lua.backup`
- Manual verification: Look for "DCS-OVERLAY" comment in file
- Location: `C:\Users\[YourName]\Saved Games\DCS\Scripts\Export.lua`

## Development

### For Developers & Contributors

**Prerequisites:**
- Node.js v14+ and npm
- Inno Setup 6+ (for building installer)
- Git for version control

**Setup:**
```bash
git clone https://github.com/Dillen198/DCS-OVERLAYER.git
cd DCS-OVERLAYER
npm install
```

**Development Mode:**
```bash
npm start
```
Opens overlay at `http://localhost:3000` for testing

**Building:**
```bash
npm run build           # Build executable and assets
npm run package:win     # Create Windows installer
```

**Output:**
- `dist/DCS-Overlay.exe` - Standalone executable
- `release/DCS-Overlay-Setup-v1.0.0.exe` - Distribution installer

## Project Architecture

```
dcs-overlay/
├── installer.js         # Main application with auto-installer
├── build.js            # Build automation script
├── Export.lua          # DCS export script (Lua)
├── overlay.html        # Web UI (HTML/CSS/JS)
├── installer.iss       # Inno Setup configuration
├── package.json        # Node.js dependencies
├── mappings/
│   ├── aircraft.json   # Aircraft icon mappings
│   └── weapons.json    # Weapon type mappings
└── images/
    ├── aircraft/       # Aircraft module icons
    └── weapons/        # Weapon system icons
```

**Data Flow:**
```
DCS World → Export.lua → JSON File → Node.js Bridge → WebSocket → Browser → OBS
```

## Contributing

Contributions from the DCS community are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Areas for Contribution:**
- Additional aircraft icon support
- Weapon system recognition improvements
- Alternative overlay layouts
- Localization/translations
- Documentation improvements

## License

GNU General Public License v3.0 with Commons Clause

Free for non-commercial use. See LICENSE.txt for complete terms.

Commercial licensing available upon request.

## Credits

**Developer**: №15 | KillerDog

Built for the DCS World streaming and content creation community using the official DCS export API.

## Support & Community

- **Bug Reports**: [GitHub Issues](https://github.com/Dillen198/DCS-OVERLAYER/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/Dillen198/DCS-OVERLAYER/discussions)
- **Community Discord**: [Join Server](https://discord.gg/SuTqTaFR7T)
- **Streaming Tips**: Check Discord #streaming-setup channel

## Changelog

### v1.0.0 (September 2025)
- Initial public release
- Automatic installer with DCS detection
- Real-time weapons and fuel monitoring
- OBS/streaming software integration
- Support for all DCS aircraft modules
- Compatible with existing export mods (SRS, TacView)
- Professional broadcast-quality overlay design

---

**Enhance your DCS streams with professional real-time data overlay**
