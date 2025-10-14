# Fresh Installation Plan: Minimal Kangaroo Configuration

## 🎯 Goal
Create a clean, minimal installation of the kangaroo-electron deployment repository by resetting to the original Holochain kangaroo-electron base with minimal configuration for requests-and-offers.

## 📋 Current State Analysis

**Current Repository**: `requests-and-offers-kangaroo-electron`
- Complex with splashscreen, extensive configuration
- Multiple custom scripts and validation logic
- Heavy deployment automation
- Version: 0.1.8 with network invite system

**Target State**: Clean base + minimal requests-and-offers config
- Original Holochain kangaroo-electron functionality
- Essential configuration only
- Simple deployment process
- No splashscreen, minimal complexity

## 🔄 Migration Strategy Options

### Option A: Complete Reset (Recommended) ⭐
**Reset to original holochain/kangaroo-electron + minimal config**

### Option B: Selective Cleanup
**Remove splashscreen and simplify existing repo**

### Option C: Fork and Rebuild
**Create fresh fork from original with minimal changes**

---

## 🚀 Option A: Complete Reset Implementation

### Phase 1: Repository Reset

#### 1.1 Backup Current Configuration
```bash
# Create backup of essential configs
mkdir -p ../kangaroo-backup
cp kangaroo.config.ts ../kangaroo-backup/config-backup.ts
cp package.json ../kangaroo-backup/package-backup.json
cp -r scripts ../kangaroo-backup/scripts-backup
```

#### 1.2 Reset to Original Repository
```bash
# Remove existing remote and add original
git remote remove origin
git remote add upstream https://github.com/holochain/kangaroo-electron.git
git fetch upstream
git reset --hard upstream/main

# Add your fork as new remote
git remote add origin https://github.com/happenings-community/requests-and-offers-kangaroo-electron.git
```

#### 1.3 Update Repository Identity
```bash
# Update package.json with requests-and-offers identity
{
  "name": "requests-and-offers.happenings-community.kangaroo-electron",
  "productName": "Requests and Offers",
  "description": "Community-driven exchange platform powered by Holochain",
  "version": "0.2.0"
}
```

### Phase 2: Minimal Configuration Application

#### 2.1 Create Minimal kangaroo.config.ts
```typescript
import { defineConfig } from './src/main/defineConfig';

const config = defineConfig({
  // Essential app identity
  appId: 'requests-and-offers.happenings-community.kangaroo-electron',
  productName: 'Requests and Offers',
  version: '0.2.0',

  // Security and signing (disabled for simplicity)
  macOSCodeSigning: false,
  windowsEVCodeSigning: false,
  autoUpdates: false,

  // Essential UI settings
  fallbackToIndexHtml: true,
  systray: true,
  passwordMode: 'no-password',

  // Network configuration (match your main app)
  networkSeed: 'requests-and-offers-2025',
  bootstrapUrl: 'https://holostrap.elohim.host/',
  signalUrl: 'wss://holostrap.elohim.host/',
  iceUrls: ['stun:stun.cloudflare.com:3478', 'stun:stun.l.google.com:19302'],

  // Holochain binary versions (use latest stable)
  bins: {
    holochain: {
      version: '0.5.5',
      // Use checksums from original config or latest
    },
    lair: {
      version: '0.6.2',
      // Use checksums from original config or latest
    },
  },
});

export default config;
```

#### 2.2 Update Webhapp Configuration
```bash
# Update scripts to point to your requests-and-offers webhapp
# Modify fetch-webhapp.js to use your release URL
```

#### 2.3 Simplify Build Scripts
```json
{
  "scripts": {
    "setup": "bun install && bun run fetch:binaries && bun run fetch:webhapp",
    "dev": "bun run setup && electron-vite dev",
    "build": "bun run setup && electron-vite build",
    "build:all": "bun run build && electron-builder --mac --win --linux",
    "lint": "eslint --ext .ts,.tsx .",
    "typecheck": "tsc --noEmit"
  }
}
```

### Phase 3: Essential Customizations

#### 3.1 App Icon and Branding
```bash
# Add requests-and-offers icon to src/assets/
# Update electron-builder.yml to use your icon
```

#### 3.2 Simplified Electron Builder Config
```yaml
appId: requests-and-offers.happenings-community.kangaroo-electron
productName: Requests and Offers
directories:
  output: release
files:
  - out
  - pouch
asarUnpack:
  - pouch
mac:
  category: public.app-category.productivity
win:
  target:
    - target: nsis
      arch:
        - x64
linux:
  target:
    - target: AppImage
      arch:
        - x64
```

#### 3.3 Remove Splashscreen Logic
```typescript
// Simplify main.ts - remove splashscreen references
// Directly load main window
```

### Phase 4: Testing and Validation

#### 4.1 Local Development Test
```bash
# Test basic functionality
bun run setup
bun run dev

# Verify:
# - App launches without splashscreen
# - Webhapp loads correctly
# - Holochain conductor starts
# - Network connection works
```

#### 4.2 Build Test
```bash
# Test build process
bun run build

# Verify:
# - Build completes successfully
# - All platforms build
# - Icons and branding applied correctly
```

#### 4.3 Network Synchronization Test
```bash
# Test with same network seed as main app
# Verify data synchronization between desktop app and kangaroo
```

---

## 🔧 Option B: Selective Cleanup Implementation

### Remove Splashscreen Components
```bash
# Remove splashscreen files
rm -f src/preload/splashscreen.ts
rm -rf src/renderer/splashscreen/
rm -rf assets/splashscreen/

# Update main.ts to remove splashscreen logic
# Simplify window creation
```

### Simplify Configuration
```typescript
// Remove complex validation logic from kangaroo.config.ts
// Keep only essential settings
// Remove deployment restrictions and checks
```

### Remove Heavy Automation
```bash
# Remove complex deployment scripts
# Keep only essential build scripts
# Simplify CI/CD pipeline
```

---

## 📊 Comparison of Approaches

| Aspect | Option A (Reset) | Option B (Cleanup) | Option C (Fork) |
|--------|------------------|-------------------|-----------------|
| **Complexity** | Low (fresh start) | Medium (careful removal) | Low (clean fork) |
| **Risk** | Low (known base) | High (might break things) | Low (controlled changes) |
| **Maintenance** | Easy (minimal changes) | Medium (complex codebase) | Easy (targeted changes) |
| **Time Investment** | 2-3 hours | 4-6 hours | 3-4 hours |
| **Future Updates** | Easy (track original) | Hard (diverged) | Easy (targeted merges) |

---

## 🎯 Recommended Path: Option A (Complete Reset)

### Why This Approach is Best

1. **Minimal Complexity**: Start with clean, working base
2. **Future Proof**: Easy to sync with upstream updates
3. **Reduced Risk**: Avoid inherited complexity
4. **Clear Documentation**: Changes are explicit and minimal
5. **Maintenance**: Much easier to maintain and debug

### Implementation Timeline

**Day 1**: Repository reset and basic configuration
- Backup current state
- Reset to original repository
- Apply minimal branding

**Day 2**: Configuration and testing
- Configure webhapp integration
- Test local development
- Validate network synchronization

**Day 3**: Build and deployment
- Configure build process
- Test all platform builds
- Set up simplified CI/CD

### Success Criteria

✅ **Functional Requirements**:
- App launches without splashscreen
- Loads requests-and-offers webhapp correctly
- Connects to Holochain network
- Synchronizes with main app network

✅ **Technical Requirements**:
- Clean, minimal codebase
- Simple build process
- Cross-platform builds work
- Easy to maintain and update

✅ **Operational Requirements**:
- Reduced deployment complexity
- Clear documentation
- Simple configuration management

---

## 🚦 Rollback Plan

If issues arise during reset:

```bash
# Quick rollback to backup state
git checkout main
git reset --hard HEAD~1  # Or specific commit hash

# Restore from backup if needed
cp ../kangaroo-backup/* ./
```

---

## 📝 Next Steps

1. **Choose approach** (recommend Option A)
2. **Schedule implementation** (suggest during development window)
3. **Prepare test environment** (ensure webhapp availability)
4. **Communicate changes** to team/stakeholders
5. **Execute plan** following selected approach
6. **Document lessons learned** for future reference

---

## 🔄 Future Considerations

Once minimal installation is complete:

1. **EdgeNode Integration**: Add EdgeNode deployment option
2. **Automated Updates**: Implement simple update mechanism
3. **Enhanced Security**: Add code signing for production
4. **Cross-Platform Testing**: Establish regular testing workflow
5. **Documentation**: Maintain clear setup and deployment guides

This plan provides a clean foundation that balances simplicity with functionality, making future enhancements much more manageable.