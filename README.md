# DCS Military Overlay with RWR Support

A real-time overlay for DCS World that displays aircraft weapons, fuel status, and RWR (Radar Warning Receiver) threats.

## Features

- **Aircraft Information**: Shows current aircraft with icon
- **Weapons Display**: Air-to-Air and Air-to-Ground weapons with counts
- **Fuel Status**: Visual fuel bar with remaining fuel and estimated time
- **RWR Display**: Real-time radar warning receiver showing threats on a circular scope

## Prerequisites

- **DCS World** installed
- **Node.js** (v14 or higher) - [Download here](https://nodejs.org/)

## Installation

1. **Install Dependencies**
   ```bash
   npm install
   ```

2. **Install Export Script in DCS**
   
   Copy `Export.lua` to your DCS Scripts folder:
   ```
   C:\Users\[YourUsername]\Saved Games\DCS\Scripts\Export.lua
   ```
   
   If `Export.lua` already exists, append the content instead of replacing.

## Running the Overlay

### Step 1: Start the Bridge Server

Open a terminal in the project folder and run:

```bash
node websocket-bridge.js
```

You should see:
```
UDP server listening on 0.0.0.0:12340
WebSocket server listening on port 8080
HTTP server listening on http://localhost:3000
Monitoring DCS data file: C:\Users\...\Saved Games\DCS\Temp\dcs_overlay_data.json
```

### Step 2: Open the Overlay

Open your browser and go to:
```
http://localhost:3000
```

### Step 3: Launch DCS World

1. Start DCS World
2. Enter a mission or free flight
3. The overlay will automatically connect and display your aircraft data

## Usage

- **Left Side**: Weapons loadout and fuel status
- **Top Right**: RWR display showing radar threats
  - **Red**: Missile lock or launch
  - **Orange**: Tracking radar
  - **Yellow**: Search radar

## Troubleshooting

**"Connecting to DCS..." stays on screen**
- Ensure DCS is running with an aircraft loaded
- Check that `Export.lua` is in the correct folder
- Verify the bridge server is running

**No weapons showing**
- Make sure aircraft has weapons loaded in mission editor
- Check browser console (F12) for errors

**RWR not showing threats**
- Ensure enemy radar systems are in the mission
- RWR only shows threats within detection range

**Bridge server won't start**
- Check if port 3000, 8080, or 12340 are already in use
- Run `npm install` again to ensure dependencies are installed

## File Structure

```
dcs-overlay/
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

## Technical Details

- **Export Script**: Runs inside DCS, exports data to JSON file
- **Bridge Server**: Reads JSON file and serves data via WebSocket
- **Overlay**: HTML/CSS/JavaScript UI that displays data in real-time

## Credits

Built for DCS World using official DCS API.

## License

MIT