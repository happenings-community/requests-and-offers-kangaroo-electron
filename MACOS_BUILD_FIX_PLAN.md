# macOS Build Issue - Alpha 6 Fix Plan

## Issue Summary
**Date Identified**: August 24, 2025  
**Version Affected**: v0.1.0-alpha.6  
**Platform**: macOS (both ARM64 and x64)  
**Status**: 🔴 Critical - App fails to launch

## Error Details

### User-Reported Error
```
A JavaScript error occurred in the main process
Uncaught Exception:
Error: Cannot find module '@holochain/hc-spin-rust-utils-darwin-arm64'
Require stack:
- /Applications/Requests and Offers.app/Contents/Resources/app.asar/node_modules/@holochain/hc-spin-rust-utils/index.js
- /Applications/Requests and Offers.app/Contents/Resources/app.asar/out/main/index.js
```

### Root Cause Analysis

1. **Native Module Packaging Issue**: The `@holochain/hc-spin-rust-utils` package contains platform-specific native bindings that aren't being properly bundled during the Electron build process.

2. **ASAR Archive Limitation**: Electron's ASAR archive format doesn't properly handle native Node.js modules (.node files), causing them to be inaccessible at runtime.

3. **Missing Platform-Specific Dependencies**: The build process isn't including the required darwin-arm64 and darwin-x64 specific modules in the final DMG.

## Solution Plan

### Step 1: Fix Electron Builder Configuration

**File**: `electron-builder-template.yml`

Add the following configuration to properly handle native modules:

```yaml
# Add to existing configuration
asarUnpack:
  - "**/@holochain/hc-spin-rust-utils/**"
  - "**/@holochain/hc-spin-rust-utils-*/**"
  - "**/*.node"

npmRebuild: true
includeSubNodeModules: true

mac:
  # Ensure native deps are included
  extraFiles:
    - from: "node_modules/@holochain/hc-spin-rust-utils-darwin-${arch}"
      to: "Resources/app.asar.unpacked/node_modules/@holochain/hc-spin-rust-utils-darwin-${arch}"
      filter: ["**/*"]
```

### Step 2: Update Package Dependencies

**File**: `package.json`

Add platform-specific optional dependencies:

```json
{
  "dependencies": {
    "@holochain/hc-spin-rust-utils": "^0.500.0"
  },
  "optionalDependencies": {
    "@holochain/hc-spin-rust-utils-darwin-arm64": "^0.500.0",
    "@holochain/hc-spin-rust-utils-darwin-x64": "^0.500.0",
    "@holochain/hc-spin-rust-utils-darwin-universal": "^0.500.0"
  }
}
```

### Step 3: Create Native Dependency Preparation Script

**New File**: `scripts/prepare-native-deps.js`

```javascript
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function prepareNativeDeps() {
  console.log('Preparing native dependencies for macOS build...');
  
  // Force rebuild of native modules
  try {
    execSync('npm rebuild @holochain/hc-spin-rust-utils', { stdio: 'inherit' });
    
    // Verify the module exists
    const modulePath = path.join(
      process.cwd(),
      'node_modules',
      '@holochain',
      'hc-spin-rust-utils'
    );
    
    if (!fs.existsSync(modulePath)) {
      throw new Error('hc-spin-rust-utils module not found after rebuild');
    }
    
    console.log('✅ Native dependencies prepared successfully');
  } catch (error) {
    console.error('❌ Failed to prepare native dependencies:', error);
    process.exit(1);
  }
}

prepareNativeDeps();
```

### Step 4: Update Build Scripts

**File**: `package.json` (scripts section)

```json
{
  "scripts": {
    "prebuild": "node ./scripts/prepare-native-deps.js",
    "build:mac-arm64": "npm run prebuild && npm run build && electron-builder --mac --arm64 --config",
    "build:mac-x64": "npm run prebuild && npm run build && electron-builder --mac --x64 --config"
  }
}
```

### Step 5: Update GitHub Actions Workflow

**File**: `.github/workflows/release.yml` (or equivalent)

Add native module handling to the macOS build job:

```yaml
- name: Install and rebuild native dependencies
  run: |
    npm ci
    npm rebuild @holochain/hc-spin-rust-utils
    npm ls @holochain/hc-spin-rust-utils || true
    
- name: Verify native modules
  run: |
    ls -la node_modules/@holochain/ || echo "Module directory check"
    node -e "require('@holochain/hc-spin-rust-utils')" || echo "Module load test failed"
```

## Immediate Workaround for Users

Until the fix is released, users can work around the issue:

### Option 1: Manual Fix After Installation
```bash
# After installing the app
cd "/Applications/Requests and Offers.app/Contents/Resources"
mkdir -p app.asar.unpacked/node_modules/@holochain
cd app.asar.unpacked
npm install @holochain/hc-spin-rust-utils@0.500.0
```

### Option 2: Use Homebrew with Post-Install Fix
Update the Homebrew formula temporarily with:

```ruby
postflight do
  # Remove quarantine
  system_command "/usr/bin/xattr",
                 args: ["-r", "-d", "com.apple.quarantine", "#{appdir}/Requests and Offers.app"],
                 sudo: false
                 
  # Fix native module issue
  system_command "/bin/sh",
                 args: ["-c", "cd '#{appdir}/Requests and Offers.app/Contents/Resources' && mkdir -p app.asar.unpacked/node_modules/@holochain && cd app.asar.unpacked && npm install @holochain/hc-spin-rust-utils@0.500.0"],
                 sudo: false
end
```

## Testing Checklist

- [ ] Build DMG for ARM64 (Apple Silicon)
- [ ] Build DMG for x64 (Intel)
- [ ] Test installation on macOS ARM64
- [ ] Test installation on macOS x64
- [ ] Verify app launches without errors
- [ ] Test core functionality
- [ ] Update Homebrew formula
- [ ] Test Homebrew installation

## Release Plan

1. **Version**: Release as v0.1.0-alpha.6.1 (patch release)
2. **Testing**: Internal testing on both architectures
3. **Documentation**: Update installation docs with any changes
4. **Communication**: Notify users about the fix

## References

- Original error report: Discord/Community feedback
- Related module: https://github.com/holochain/hc-spin-rust-utils
- Electron native modules: https://www.electronjs.org/docs/latest/tutorial/using-native-node-modules
- Electron Builder docs: https://www.electron.build/configuration/configuration#asarunpack

## Notes

- The issue only affects macOS builds, not Windows or Linux
- The problem is specific to how Electron packages native Node.js modules
- This is a common issue with Electron apps using native dependencies
- Consider long-term migration to N-API for better compatibility