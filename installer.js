// DCS Overlay Installer and Launcher
const dgram = require('dgram');
const WebSocket = require('ws');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const os = require('os');

const UDP_PORT = 12340;
const WS_PORT = 8080;
const HTTP_PORT = 3000;

// Determine base path (different for exe vs node)
const basePath = process.pkg ? path.dirname(process.execPath) : __dirname;

// Configuration
let config = {
    dcsPath: '',
    firstRun: true
};

const configFile = path.join(basePath, 'config.json');

// Load or create config
function loadConfig() {
    try {
        if (fs.existsSync(configFile)) {
            config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
        } else {
            config.dcsPath = findDCSPath();
            config.firstRun = true; // Always run setup first time
            saveConfig();
        }
    } catch (error) {
        console.error('Error loading config:', error.message);
        config.dcsPath = findDCSPath();
        config.firstRun = true;
    }
}

// Save config
function saveConfig() {
    try {
        fs.writeFileSync(configFile, JSON.stringify(config, null, 2));
    } catch (error) {
        console.error('Error saving config:', error.message);
    }
}

// Find DCS Saved Games path
function findDCSPath() {
    const possiblePaths = [
        path.join(os.homedir(), 'Saved Games', 'DCS'),
        path.join(os.homedir(), 'Saved Games', 'DCS.openbeta'),
        path.join(os.homedir(), 'Saved Games', 'DCS_server')
    ];
    
    for (const dcsPath of possiblePaths) {
        if (fs.existsSync(dcsPath)) {
            console.log(`Found DCS at: ${dcsPath}`);
            return dcsPath;
        }
    }
    
    return '';
}

// Install Export.lua
function installExportScript(dcsPath) {
    try {
        const scriptsDir = path.join(dcsPath, 'Scripts');
        const exportPath = path.join(scriptsDir, 'Export.lua');
        const sourceExport = path.join(basePath, 'Export.lua');
        
        if (!fs.existsSync(sourceExport)) {
            console.error('✗ Export.lua not found in application directory!');
            return false;
        }
        
        // Create Scripts directory if it doesn't exist
        if (!fs.existsSync(scriptsDir)) {
            fs.mkdirSync(scriptsDir, { recursive: true });
            console.log('Created Scripts directory');
        }
        
        // Check if Export.lua exists
        if (fs.existsSync(exportPath)) {
            // Backup existing file
            const backupPath = path.join(scriptsDir, 'Export.lua.backup');
            fs.copyFileSync(exportPath, backupPath);
            console.log('Backed up existing Export.lua');
        }
        
        // Copy our Export.lua
        fs.copyFileSync(sourceExport, exportPath);
        console.log('✓ Export.lua installed successfully!');
        console.log(`  Location: ${exportPath}`);
        return true;
    } catch (error) {
        console.error('✗ Error installing Export.lua:', error.message);
        return false;
    }
}

// Setup wizard
async function runSetup() {
    console.log('\n╔════════════════════════════════════════╗');
    console.log('║     DCS Overlay - First Time Setup    ║');
    console.log('╚════════════════════════════════════════╝\n');
    
    // If DCS path found, install automatically
    if (config.dcsPath) {
        console.log(`✓ DCS Found: ${config.dcsPath}\n`);
        
        if (installExportScript(config.dcsPath)) {
            config.firstRun = false;
            saveConfig();
            return true;
        }
        return false;
    }
    
    // DCS path not found - ask user
    console.log('⚠ DCS Saved Games folder not found automatically.\n');
    console.log('Please enter your DCS Saved Games path:');
    console.log('Example: C:\\Users\\YourName\\Saved Games\\DCS\n');
    
    // For exe, we can't use readline, so provide instructions
    if (process.pkg) {
        console.log('Please edit config.json and add your DCS path like this:');
        console.log('{\n  "dcsPath": "C:\\\\Users\\\\YourName\\\\Saved Games\\\\DCS",\n  "firstRun": false\n}\n');
        saveConfig();
        console.log('Press any key to exit...');
        process.stdin.setRawMode(true);
        process.stdin.resume();
        process.stdin.on('data', process.exit.bind(process, 0));
        return false;
    }
    
    // For node development, use readline
    const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
    });
    
    return new Promise((resolve) => {
        readline.question('DCS Path: ', (answer) => {
            readline.close();
            
            if (answer && fs.existsSync(answer)) {
                config.dcsPath = answer;
                config.firstRun = false;
                saveConfig();
                
                if (installExportScript(config.dcsPath)) {
                    resolve(true);
                } else {
                    resolve(false);
                }
            } else {
                console.log('\n✗ Invalid path. Please restart and try again.\n');
                resolve(false);
            }
        });
    });
}

// Main server code
let DCS_DATA_FILE = '';

const udpServer = dgram.createSocket('udp4');

const httpServer = http.createServer((req, res) => {
    let filePath = req.url === '/' ? 'overlay.html' : req.url.substring(1);
    
    // Always look in the same directory as the executable
    const fullPath = path.join(basePath, filePath);
    
    const extname = String(path.extname(fullPath)).toLowerCase();
    const mimeTypes = {
        '.html': 'text/html',
        '.js': 'text/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml'
    };
    
    const contentType = mimeTypes[extname] || 'application/octet-stream';
    
    fs.readFile(fullPath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 - File Not Found</h1><p>Looking for: ' + fullPath + '</p>', 'utf-8');
            } else {
                res.writeHead(500);
                res.end('Error: ' + error.code, 'utf-8');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

const wss = new WebSocket.Server({ port: WS_PORT });

let latestData = null;
let lastFileModTime = 0;

function readDCSDataFile() {
    if (!DCS_DATA_FILE) return;
    
    try {
        const stats = fs.statSync(DCS_DATA_FILE);
        const modTime = stats.mtime.getTime();
        
        if (modTime > lastFileModTime) {
            lastFileModTime = modTime;
            const fileContent = fs.readFileSync(DCS_DATA_FILE, 'utf8');
            
            if (fileContent.trim()) {
                latestData = JSON.parse(fileContent);
                
                wss.clients.forEach((client) => {
                    if (client.readyState === WebSocket.OPEN) {
                        client.send(fileContent);
                    }
                });
            }
        }
    } catch (error) {
        if (error.code !== 'ENOENT') {
            console.error('Error reading file:', error.message);
        }
    }
}

udpServer.on('message', (msg, rinfo) => {
    try {
        latestData = JSON.parse(msg.toString());
        
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(msg.toString());
            }
        });
    } catch (error) {
        console.error('Error parsing UDP:', error);
    }
});

udpServer.on('error', (err) => {
    console.error('UDP server error:', err);
});

udpServer.on('listening', () => {
    const address = udpServer.address();
    console.log(`✓ UDP server: ${address.address}:${address.port}`);
});

wss.on('connection', (ws) => {
    console.log('Overlay connected');
    
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

// Start everything
async function start() {
    try {
        loadConfig();
        
        if (config.firstRun) {
            const success = await runSetup();
            if (!success) {
                console.log('\nSetup incomplete. Please restart after configuration.');
                console.log('\nPress any key to exit...');
                if (process.pkg) {
                    process.stdin.setRawMode(true);
                    process.stdin.resume();
                    process.stdin.on('data', process.exit.bind(process, 0));
                }
                return;
            }
        }
        
        // Set DCS data file path after config is loaded
        DCS_DATA_FILE = config.dcsPath ? 
            path.join(config.dcsPath, 'Temp', 'dcs_overlay_data.json') : '';
        
        console.log('\n╔════════════════════════════════════════╗');
        console.log('║        DCS Overlay - Running           ║');
        console.log('╚════════════════════════════════════════╝\n');
        
        udpServer.bind(UDP_PORT);
        console.log(`✓ WebSocket server: ${WS_PORT}`);
        
        httpServer.listen(HTTP_PORT, () => {
            console.log(`✓ HTTP server: http://localhost:${HTTP_PORT}`);
            console.log(`✓ Monitoring: ${DCS_DATA_FILE}\n`);
            console.log('Opening browser...\n');
            
            // Open browser
            exec(`start http://localhost:${HTTP_PORT}`);
            
            console.log('Ready! Start DCS World to see your aircraft data.\n');
        });
        
        setInterval(readDCSDataFile, 100);
    } catch (error) {
        console.error('\n✗ Fatal error:', error.message);
        console.log('\nPress any key to exit...');
        if (process.pkg) {
            process.stdin.setRawMode(true);
            process.stdin.resume();
            process.stdin.on('data', process.exit.bind(process, 0));
        }
    }
}

process.on('SIGINT', () => {
    console.log('\nShutting down...');
    udpServer.close();
    wss.close();
    httpServer.close();
    process.exit(0);
});

start();