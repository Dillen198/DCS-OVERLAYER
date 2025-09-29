// Build script with automatic asset copying
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('Building DCS Overlay...\n');

// Step 1: Run pkg to create executable
console.log('1. Creating executable...');
try {
    execSync('pkg . --output dist/DCS-Overlay.exe', { stdio: 'inherit' });
    console.log('✓ Executable created\n');
} catch (error) {
    console.error('✗ Failed to create executable');
    process.exit(1);
}

// Step 2: Copy assets to dist folder
console.log('2. Copying assets...');

const assetsToCopy = [
    { src: 'overlay.html', dest: 'dist/overlay.html' },
    { src: 'Export.lua', dest: 'dist/Export.lua' },
    { src: 'mappings', dest: 'dist/mappings', isDir: true },
    { src: 'images', dest: 'dist/images', isDir: true }
];

// Helper function to copy directory recursively
function copyDir(src, dest) {
    if (!fs.existsSync(dest)) {
        fs.mkdirSync(dest, { recursive: true });
    }
    
    const entries = fs.readdirSync(src, { withFileTypes: true });
    
    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);
        
        if (entry.isDirectory()) {
            copyDir(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

// Copy each asset
for (const asset of assetsToCopy) {
    try {
        if (!fs.existsSync(asset.src)) {
            console.error(`✗ Source not found: ${asset.src}`);
            continue;
        }
        
        if (asset.isDir) {
            copyDir(asset.src, asset.dest);
            console.log(`✓ Copied ${asset.src}/ folder`);
        } else {
            fs.copyFileSync(asset.src, asset.dest);
            console.log(`✓ Copied ${asset.src}`);
        }
    } catch (error) {
        console.error(`✗ Failed to copy ${asset.src}:`, error.message);
    }
}

console.log('\n✓ Build complete!');
console.log('\nOutput location: dist/DCS-Overlay.exe');
console.log('All required files copied to dist/ folder');
console.log('\nTo distribute, zip the entire dist/ folder.\n');