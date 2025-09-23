# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Holochain Kangaroo Electron application for "Requests and Offers" - a community-driven exchange platform. It packages a Holochain app into a cross-platform desktop application using Electron.

## Development Commands

### Setup and Installation
```bash
# Initial setup - installs deps, fetches binaries and webhapp, writes configs
yarn setup

# Alternative with bun
bun run setup
```

### Development
```bash
# Run in development mode with hot-reload
yarn dev
# or
bun run dev

# Type checking
yarn typecheck        # Check both node and web
yarn typecheck:node   # Check node/main process only
yarn typecheck:web    # Check web/renderer process only

# Linting
yarn lint
```

### Building
```bash
# Platform-specific builds
yarn build:linux      # Linux (AppImage, .deb)
yarn build:mac-arm64  # macOS Apple Silicon
yarn build:mac-x64    # macOS Intel
yarn build:win        # Windows

# Pre-build steps (automatically called by build commands)
yarn prebuild         # Prepare native dependencies
```

### Release Process
1. Update version in `kangaroo.config.ts`
2. Create draft release on GitHub with tag `v{version}` (e.g., `v0.1.0`)
3. Merge main into release branch and push to trigger CI build:
```bash
git checkout release
git merge main
git push
```

## Architecture

### Core Components

**Electron Main Process (`src/main/`)**
- `index.ts` - Main entry point, IPC handlers, app lifecycle
- `holochainManager.ts` - Manages Holochain conductor lifecycle
- `lairKeystore.ts` - Handles Lair keystore for cryptographic operations
- `filesystem.ts` - Manages app data directories with semver-based versioning
- `launch.ts` - Application launch logic and initialization
- `windows.ts` - Window management (main, splash screens)
- `cli.ts` - Command-line argument parsing and validation

**Configuration**
- `kangaroo.config.ts` - Central configuration for app metadata, versions, and network settings
- `electron-builder.yml` - Electron Builder configuration for packaging

**Scripts (`scripts/`)**
- `fetch-binaries.js` - Downloads Holochain and Lair binaries
- `fetch-webhapp.js` - Downloads or validates the webhapp file
- `unpack-pouch.js` - Extracts webhapp UI assets
- `write-configs.js` - Generates runtime configuration files

### Key Concepts

**Semver-based Data Management**: Different semver-incompatible versions maintain separate data stores. For example, v0.1.0 and v0.2.0 will have independent conductors and databases.

**Webhapp Integration**: The `.webhapp` file in `pouch/` contains the Holochain DNA and UI. It's unpacked during build to extract UI assets and icon.

**Network Configuration**: Bootstrap, signal, and ICE servers are configured in `kangaroo.config.ts`. These are critical for peer discovery and should be reliable for production deployments.

## Holochain Integration

The app uses Holochain v0.5.x with:
- **Conductor**: Manages DNA instances and agent keys
- **Lair Keystore**: Handles cryptographic operations
- **WebSocket API**: Communication between Electron and Holochain

Binary versions and checksums are specified in `kangaroo.config.ts` under the `bins` field.

## Platform-Specific Considerations

**macOS**:
- Unsigned apps require quarantine removal: `xattr -r -d com.apple.quarantine "/Applications/Requests and Offers.app"`
- Supports both ARM64 (Apple Silicon) and x64 (Intel)
- Code signing configuration available but disabled by default

**Windows**:
- EV code signing support available but disabled by default
- NSIS installer for distribution

**Linux**:
- Builds as AppImage and .deb packages
- Requires standard build tools for native dependencies

## CI/CD Pipeline

GitHub Actions workflow (`/.github/workflows/release.yaml`):
- Triggers on push to `release` branch
- Builds for all platforms in parallel
- Handles native dependency compilation per platform
- Artifacts attached to GitHub releases

## Testing Profiles

Use CLI flags for testing different configurations:
```bash
# Custom profile with separate data
--profile <name>

# Custom network seed
--network-seed <seed>

# Custom bootstrap/signal servers
--bootstrap-url <url>
--signal-url <url>

# Debug logging
--holochain-rust-log <level>
--print-holochain-logs
```

## Important Files

- `pouch/requests_and_offers.webhapp` - The Holochain application bundle (Ensure it is up-to-date)
- `resources/` - Generated at build time, contains UI assets and icons
- `out/` - Electron-vite build output
- `dist/` - Final packaged applications
