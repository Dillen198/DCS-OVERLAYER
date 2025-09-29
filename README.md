# DCS World Overlay

A real-time overlay for DCS World that displays aircraft weapons, fuel status.

## Features

- **Aircraft Information**: Shows current aircraft with icon
- **Weapons Display**: Air-to-Air and Air-to-Ground weapons with counts
- **Fuel Status**: Visual fuel bar with remaining fuel and estimated time

## Quick Start (For Users)

### Download

1. Go to [Releases](../../releases)
2. Download the latest `DCS-Overlay-vX.X.X-Windows-x64.zip`
3. Extract to any folder

### Installation

1. **Install Export Script**
   
   Copy `Export.lua` to your DCS Scripts folder:
   ```
   C:\Users\[YourUsername]\Saved Games\DCS\Scripts\Export.lua
   ```
   
   **Important:** If `Export.lua` already exists, append the content instead of replacing.

2. **Run the Overlay**
   
   Double-click `DCS-Overlay.exe`
   
   Your browser will automatically open to `http://localhost:3000`

3. **Launch DCS World**
   
   Start DCS and enter any mission. The overlay will automatically connect and display your aircraft data.

## System Requirements

- Windows 10/11 (64-bit)
- DCS World (any version)
- Modern web browser (Chrome, Firefox, Edge)

## Usage

- **Left Side**: Weapons loadout and fuel status    

## Troubleshooting

### "Connecting to DCS..." stays on screen
- Ensure DCS is running with an aircraft loaded
- Check that `Export.lua` is in the correct folder: `C:\Users\[YourUsername]\Saved Games\DCS\Scripts\`
- Verify the overlay server is running (console window should be open)

### No weapons showing
- Make sure aircraft has weapons loaded in mission editor
- Check browser console (F12) for errors

### Windows Security Warning
- Click "More info" → "Run anyway"
- This is normal for unsigned executables
- Optionally, add to Windows Defender exceptions

### Port Already in Use
- Close any applications using ports 3000, 8080, or 12340
- Or modify ports in `websocket-bridge.js` before building

### Overlay not updating
- Refresh the browser page (F5)
- Restart `DCS-Overlay.exe`
- Check DCS logs for export script errors

## Development

### Prerequisites

- Node.js (v14 or higher)
- npm

### Setup

```bash
npm install
```

### Run Development Server

```bash
npm start
```

Then open `http://localhost:3000` in your browser.

### Build EXE

```bash
npm install -g pkg
npm run build
```

Output: `dist/DCS-Overlay.exe`

## File Structure

```
dcs-overlay/
├── DCS-Overlay.exe         # Standalone executable (after build)
├── Export.lua              # DCS export script
├── websocket-bridge.js     # Node.js bridge server
├── overlay.html            # Overlay UI
├── package.json            # Node dependencies
├── mappings/
│   ├── aircraft.json       # Aircraft icon mappings
│   └── weapons.json        # Weapon icon mappings
└── images/
    ├── aircraft/           # Aircraft icons
    └── weapons/            # Weapon icons
```

## Customization

### Changing Update Rate

In `Export.lua`, modify:
```lua
local UPDATE_INTERVAL = 0.1  -- Update every 0.1 seconds
```

### Changing Overlay Position

In `overlay.html`, modify the CSS:
```css
.overlay-container {
    left: 10px;    /* Distance from left */
    bottom: 10px;  /* Distance from bottom */
}
```

### Changing Server Ports

In `websocket-bridge.js`, modify:
```javascript
const UDP_PORT = 12340;
const WS_PORT = 8080;
const HTTP_PORT = 3000;
```

## Technical Details

- **Export Script**: Runs inside DCS, exports data to JSON file
- **Bridge Server**: Reads JSON file and serves data via WebSocket
- **Overlay**: HTML/CSS/JavaScript UI that displays data in real-time

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## Credits

Built for DCS World using official DCS API.

## License

MIT

## Support

For issues, questions, or feature requests, please open an issue on GitHub.