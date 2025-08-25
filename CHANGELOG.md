## \[Unreleased\]

### Added
### Fixed
### Changed
- Updated to holochain 0.5.0-rc.1
### Removed

## \[0.1.0-alpha.6.1\] - 2025-08-25

### Fixed
- **Critical macOS Launch Issue**: Fixed app crashes with "Cannot find module '@holochain/hc-spin-rust-utils-darwin-arm64'" error
- **Native Module Packaging**: Updated electron-builder configuration to properly include native modules in the app bundle using asarUnpack patterns
- **macOS Dependencies**: Added platform-specific optional dependencies for macOS ARM64, x64, and universal builds
- **Build Process**: Enhanced GitHub Actions workflow with native module installation and verification steps

### Changed
- Updated electron-builder template to use asarUnpack for native modules instead of extraFiles
- Enhanced CI/CD pipeline with platform-specific native dependency handling
- Resolved EEXIST conflicts in electron-builder configuration