// WebSocket Bridge Server for DCS Data with File Reading
// Run with: node websocket-bridge.js

const dgram = require('dgram');
const WebSocket = require('ws');
const http = require('http');
const fs = require('fs');
const path = require('path');

const UDP_PORT = 12340;
const WS_PORT = 8080;
const HTTP_PORT = 3000;

// File path for DCS data (Windows path)
const DCS_DATA_FILE = path.join(require('os').homedir(), 'Saved Games/DCS/Temp/dcs_overlay_data.json');

// Create UDP server to receive DCS data
const udpServer = dgram.createSocket('udp4');

// Create HTTP server to serve the overlay
const httpServer = http.createServer((req, res) => {
    let filePath = '.' + req.url;
    if (filePath === './') {
        filePath = './overlay.html';
    }
    
    const extname = String(path.extname(filePath)).toLowerCase();
    const mimeTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.wav': 'audio/wav',
        '.mp4': 'video/mp4',
        '.woff': 'application/font-woff',
        '.ttf': 'application/font-ttf',
        '.eot': 'application/vnd.ms-fontobject',
        '.otf': 'application/font-otf',
        '.wasm': 'application/wasm'
    };
    
    const contentType = mimeTypes[extname] || 'application/octet-stream';
    
    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 - File Not Found</h1>', 'utf-8');
            } else {
                res.writeHead(500);
                res.end('Sorry, check with the site admin for error: ' + error.code + ' ..\n');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

// Create WebSocket server for the overlay
const wss = new WebSocket.Server({ port: WS_PORT });

let latestData = null;
let lastFileModTime = 0;

// File monitoring function
function readDCSDataFile() {
    try {
        const stats = fs.statSync(DCS_DATA_FILE);
        const modTime = stats.mtime.getTime();
        
        // Only read if file was modified
        if (modTime > lastFileModTime) {
            lastFileModTime = modTime;
            const fileContent = fs.readFileSync(DCS_DATA_FILE, 'utf8');
            
            if (fileContent.trim()) {
                latestData = JSON.parse(fileContent);
                console.log(`File data read: ${latestData.aircraft} - ${latestData.weapons?.length || 0} weapons`);
                
                // Broadcast to all connected WebSocket clients
                wss.clients.forEach((client) => {
                    if (client.readyState === WebSocket.OPEN) {
                        client.send(fileContent);
                    }
                });
            }
        }
    } catch (error) {
        // File doesn't exist or isn't ready yet - this is normal
        if (error.code !== 'ENOENT') {
            console.error('Error reading DCS data file:', error.message);
        }
    }
}

// UDP Server - receives data from DCS (fallback if socket works)
udpServer.on('message', (msg, rinfo) => {
    try {
        latestData = JSON.parse(msg.toString());
        console.log(`UDP data received: ${latestData.aircraft} - ${latestData.weapons?.length || 0} weapons`);
        
        // Broadcast to all connected WebSocket clients
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(msg.toString());
            }
        });
    } catch (error) {
        console.error('Error parsing UDP message:', error);
    }
});

udpServer.on('error', (err) => {
    console.error('UDP server error:', err);
});

udpServer.on('listening', () => {
    const address = udpServer.address();
    console.log(`UDP server listening on ${address.address}:${address.port}`);
});

// WebSocket Server - serves data to overlay
wss.on('connection', (ws) => {
    console.log('Overlay connected');
    
    // Send latest data immediately if available
    if (latestData) {
        ws.send(JSON.stringify(latestData));
    }
    
    ws.on('close', () => {
        console.log('Overlay disconnected');
    });
    
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

// Start HTTP server
httpServer.listen(HTTP_PORT, () => {
    console.log(`HTTP server listening on http://localhost:${HTTP_PORT}`);
    console.log(`Open your browser to: http://localhost:${HTTP_PORT}`);
});

// Start servers
udpServer.bind(UDP_PORT);
console.log(`WebSocket server listening on port ${WS_PORT}`);
console.log(`Monitoring DCS data file: ${DCS_DATA_FILE}`);
console.log('Bridge server started. Waiting for DCS data...');

// Start file monitoring (check every 100ms)
setInterval(readDCSDataFile, 100);

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down servers...');
    udpServer.close();
    wss.close();
    httpServer.close();
    process.exit(0);
});