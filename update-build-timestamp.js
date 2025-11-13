#!/usr/bin/env node

/**
 * Updates the build timestamp in index.html before deployment
 * This ensures each deployment has a unique timestamp for cache busting
 */

const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, 'index.html');
const timestamp = new Date().toISOString();

console.log('🔨 Updating build timestamp...');
console.log('📅 Timestamp:', timestamp);

try {
    let html = fs.readFileSync(indexPath, 'utf8');
    
    // Replace the placeholder with actual timestamp
    html = html.replace(
        'BUILD_TIMESTAMP_PLACEHOLDER',
        timestamp
    );
    
    fs.writeFileSync(indexPath, html, 'utf8');
    
    console.log('✅ Build timestamp updated successfully!');
    console.log('📄 File:', indexPath);
} catch (error) {
    console.error('❌ Error updating build timestamp:', error);
    process.exit(1);
}

