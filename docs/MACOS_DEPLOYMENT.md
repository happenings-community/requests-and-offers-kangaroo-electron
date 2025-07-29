# macOS Deployment Guide

This guide covers all aspects of deploying the Requests and Offers app for macOS.

## 📱 For End Users

### Quick Install (2 steps)

1. **Download** the appropriate `.dmg` for your Mac:
   - **Apple Silicon** (M1/M2/M3): Choose ARM64
   - **Intel Macs**: Choose x64
   - Download from: [Latest Release](https://github.com/happenings-community/requests-and-offers-kangaroo-electron/releases/latest)

2. **Remove quarantine** (required for unsigned apps):
   ```bash
   xattr -r -d com.apple.quarantine "/Applications/Requests and Offers.app"
   ```

### Alternative: Homebrew Installation

For developers and power users:

```bash
# One-time setup
brew tap happenings-community/requests-and-offers

# Install the app
brew install --cask requests-and-offers

# Future updates
brew upgrade --cask requests-and-offers
```

## 🛠️ For Developers

### Building for macOS

The project is configured to build for both Intel (x64) and Apple Silicon (ARM64):

```bash
# Build for Apple Silicon
npm run build:mac-arm64

# Build for Intel
npm run build:mac-x64
```

**Note**: Cross-platform builds (Linux → macOS) will fail due to native dependencies. Use GitHub Actions for automated macOS builds.

### Configuration

Key settings in `kangaroo.config.ts`:

```typescript
{
  macOSCodeSigning: false,  // Set to true if you have Apple Developer certificates
  // ... other settings
}
```

### Code Signing (Optional)

If you have an Apple Developer account ($99/year):

1. Set `macOSCodeSigning: true` in `kangaroo.config.ts`
2. Uncomment `afterSign: scripts/notarize.js` in `electron-builder-template.yml`
3. Configure GitHub Secrets:
   - `APPLE_DEV_IDENTITY`
   - `APPLE_ID_EMAIL`
   - `APPLE_ID_PASSWORD`
   - `APPLE_TEAM_ID`
   - `APPLE_CERTIFICATE`
   - `APPLE_CERTIFICATE_PASSWORD`

## 🍺 Homebrew Distribution

### Setting Up Your Own Tap

1. **Create tap repository**:

   ```bash
   gh repo create YOUR_ORG/homebrew-requests-and-offers --public
   ```

2. **Create formula** (`Casks/requests-and-offers.rb`):

   ```ruby
   cask "requests-and-offers" do
     version "0.1.0-alpha.5"

     if Hardware::CPU.arm?
       sha256 "SHA256_FOR_ARM64"
       url "https://github.com/YOUR_ORG/requests-and-offers-kangaroo-electron/releases/download/v#{version}/requests-and-offers-#{version}-arm64.dmg"
     else
       sha256 "SHA256_FOR_X64"
       url "https://github.com/YOUR_ORG/requests-and-offers-kangaroo-electron/releases/download/v#{version}/requests-and-offers-#{version}-x64.dmg"
     end

     name "Requests and Offers"
     desc "Holochain app for community requests and offers exchange"
     homepage "https://github.com/YOUR_ORG/requests-and-offers"

     app "Requests and Offers.app"

     # Auto-remove quarantine
     postflight do
       system_command "/usr/bin/xattr",
                      args: ["-r", "-d", "com.apple.quarantine", "#{appdir}/Requests and Offers.app"],
                      sudo: false
     end
   end
   ```

3. **Calculate SHA256**:

   ```bash
   shasum -a 256 your-app-arm64.dmg
   shasum -a 256 your-app-x64.dmg
   ```

4. **Users install with**:
   ```bash
   brew tap YOUR_ORG/requests-and-offers
   brew install --cask requests-and-offers
   ```

## 📋 Deployment Checklist

- [ ] Build DMG files for both architectures
- [ ] Test installation on macOS (both Intel and Apple Silicon if possible)
- [ ] Update version in `kangaroo.config.ts`
- [ ] Create GitHub Release with DMG files
- [ ] Update Homebrew formula with new version and SHA256
- [ ] Notify testers/users of new release

## 🚨 Troubleshooting

### "App is damaged and can't be opened"

Run the quarantine removal command:

```bash
xattr -r -d com.apple.quarantine "/Applications/Requests and Offers.app"
```

### Build Errors on Linux

macOS builds must be done on macOS or through CI/CD. Use GitHub Actions for automated builds.

### Homebrew Installation Issues

- Ensure the tap repository is public
- Verify SHA256 hashes match exactly
- Check DMG download URLs are correct

## 📚 Additional Resources

- [Electron Builder macOS Options](https://www.electron.build/configuration/mac)
- [Homebrew Cask Documentation](https://github.com/Homebrew/homebrew-cask/blob/master/doc/cask_language_reference/readme.md)
- [Apple Developer - Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
