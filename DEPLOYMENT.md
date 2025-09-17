# Deployment Guide - Requests & Offers

Complete deployment guide for the Requests & Offers Holochain application across all platforms.

## 🚀 Quick Deployment

For experienced developers who want to deploy immediately:

```bash
# Complete deployment with validation
./scripts/deploy.sh 0.1.0-alpha.8

# Deploy skipping tests (for hotfixes)
./scripts/deploy.sh 0.1.0-alpha.8 --skip-tests

# Dry run to see what would happen
./scripts/deploy.sh 0.1.0-alpha.8 --dry-run
```

## 📋 Prerequisites

Before starting deployment, ensure you have:

### Required Tools
- **Node.js** 22+ and **Bun** latest
- **GitHub CLI** (`gh`) authenticated with write access
- **Git** with access to all repositories
- **Production Bootstrap URL** configured

### Repository Structure
```
parent-directory/
├── requests-and-offers/                    # Main webapp repository
├── requests-and-offers-kangaroo-electron/  # Desktop app repository
└── homebrew-requests-and-offers/           # Homebrew formula repository
```

### Access Requirements
- Write access to all three repositories
- GitHub Actions permissions
- Release creation permissions

## 🔍 Pre-Deployment Checklist

### Automated Validation
Run the pre-deployment script to validate your setup:

```bash
./scripts/pre-deploy-check.sh
```

### Manual Verification
- [ ] **Bootstrap URL**: Verify `kangaroo.config.ts` uses `https://holostrap.elohim.host/`
- [ ] **Signal URL**: Verify signal URL is `wss://holostrap.elohim.host/`
- [ ] **Version Consistency**: All repositories have matching version numbers
- [ ] **Working Directory**: No uncommitted changes (or commit them first)
- [ ] **Tests Passing**: All tests pass locally
- [ ] **Release Notes**: Prepared and reviewed

## 📋 Step-by-Step Deployment Process

### Step 1: Preparation
```bash
# Navigate to kangaroo-electron repository
cd /path/to/requests-and-offers-kangaroo-electron

# Ensure you're on the correct branch
git checkout release
git pull origin release

# Run pre-deployment validation
./scripts/pre-deploy-check.sh
```

### Step 2: Main Repository Updates
The deployment script automatically:
1. Updates changelog with version information
2. Synchronizes version numbers across repositories
3. Commits changes with proper commit messages

### Step 3: WebApp Deployment
The script deploys the webapp by:
1. Building the Holochain DNA and packaging the webhapp
2. Running tests (unless `--skip-tests` is specified)
3. Creating GitHub release with webapp assets
4. Generating release notes

### Step 4: Desktop Application Builds
The script triggers desktop builds by:
1. Merging main branch into release branch
2. Pushing to GitHub to trigger Actions workflows
3. Building for all platforms:
   - **Windows**: `.exe` installer + auto-update files
   - **macOS Intel**: `.dmg` + `.zip` packages
   - **macOS Apple Silicon**: `.dmg` + `.zip` packages  
   - **Linux**: `.AppImage` + `.deb` packages + auto-update files

### Step 5: Build Monitoring
The monitoring script provides real-time updates:
```bash
# Automatic monitoring (included in deploy.sh)
./scripts/monitor-builds.js 0.1.0-alpha.8

# Manual monitoring
gh run list --limit 5
gh run view --log <run-id>
```

### Step 6: Homebrew Formula Update
The script automatically:
1. Downloads new macOS DMG files
2. Calculates SHA256 checksums
3. Updates Homebrew formula with new checksums
4. Commits and pushes changes

## 🖥️ Platform-Specific Build Details

### Windows Build
- **Target**: `windows-2022` runner
- **Output**: `.exe` installer with auto-update support
- **Signing**: Configurable (currently disabled)
- **Duration**: ~3-4 minutes

### macOS Builds
- **Intel**: `macos-13` runner for x64 compatibility
- **Apple Silicon**: `macos-latest` runner for ARM64
- **Output**: `.dmg` for installation, `.zip` for updates
- **Code Signing**: Configurable (currently disabled)
- **Duration**: ~4-7 minutes

### Linux Build
- **Target**: `ubuntu-22.04` runner
- **Output**: `.AppImage` (universal) and `.deb` (Debian/Ubuntu)
- **Auto-updates**: Supported via `.yml` metadata
- **Duration**: ~5-6 minutes

## 🔧 Configuration Details

### Bootstrap Server Configuration
The application uses production-grade bootstrap infrastructure:

```typescript
// kangaroo.config.ts
bootstrapUrl: 'https://holostrap.elohim.host/',
signalUrl: 'wss://holostrap.elohim.host/',
```

**Validation**: The configuration includes automatic validation that prevents deployment with test servers in production environments.

### Version Management
Version numbers must be consistent across:
- `requests-and-offers/package.json`
- `requests-and-offers-kangaroo-electron/package.json`  
- `requests-and-offers-kangaroo-electron/kangaroo.config.ts`
- `homebrew-requests-and-offers/Casks/requests-and-offers.rb`

### Network Configuration
```typescript
// Production network settings
networkSeed: 'alpha-test-2025',
iceUrls: [
  'stun:stun.cloudflare.com:3478',
  'stun:stun.l.google.com:19302'
],
```

## 🚨 Troubleshooting

### Common Issues

#### 1. macOS DMG Blockmap Errors
**Symptom**: Build fails with "no matches found for *.dmg.blockmap"
**Solution**: Fixed in workflow - blockmap files are optional
**Impact**: Main DMG files still upload successfully

#### 2. Version Mismatch Errors
**Symptom**: Pre-deployment script fails with version inconsistency
**Solution**: 
```bash
# Update all versions manually
# Then run the sync script
./scripts/sync-version.js 0.1.0-alpha.8
```

#### 3. Test Server in Production
**Symptom**: Configuration validation fails
**Solution**: Update `kangaroo.config.ts`:
```typescript
bootstrapUrl: 'https://holostrap.elohim.host/',
signalUrl: 'wss://holostrap.elohim.host/',
```

#### 4. GitHub Actions Failures
**Symptom**: Builds fail unexpectedly
**Diagnosis**:
```bash
# Check recent failures
gh run list --limit 10

# View specific failure logs
gh run view <run-id> --log-failed

# Check workflow file syntax
gh workflow view publish
```

#### 5. Homebrew Checksum Errors
**Symptom**: Formula validation fails
**Solution**:
```bash
# Recalculate checksums manually
curl -sL <dmg-url> | sha256sum

# Update formula with correct checksums
# Then test installation
brew install --cask requests-and-offers
```

### Recovery Procedures

#### Emergency Rollback
```bash
# Use the rollback script
./scripts/rollback.sh 0.1.0-alpha.6

# Or manual rollback
git checkout v0.1.0-alpha.6 -- kangaroo.config.ts package.json
git commit -m "rollback: emergency revert to v0.1.0-alpha.6"
git push origin release
```

#### Partial Deployment Recovery
If only some platforms fail:
1. Check which assets uploaded successfully
2. Retry failed builds manually if needed
3. Update Homebrew only after all macOS builds succeed

#### Asset Re-upload
```bash
# Re-upload specific assets
gh release upload v0.1.0-alpha.8 path/to/asset --clobber

# Delete and recreate release if needed
gh release delete v0.1.0-alpha.8 --yes
gh release create v0.1.0-alpha.8 --title "..." --notes "..."
```

## 📊 Monitoring and Validation

### Build Monitoring
```bash
# Real-time monitoring with visual status
./scripts/monitor-builds.js 0.1.0-alpha.8

# Manual monitoring commands
gh run list --limit 5
gh run view <run-id>
gh run view <run-id> --log
```

### Post-Deployment Validation
```bash
# Check all assets are present
gh release view v0.1.0-alpha.8 --json assets

# Test Homebrew installation
brew install --cask requests-and-offers

# Verify download links
curl -I https://github.com/.../releases/download/.../file.dmg
```

### Success Criteria
- [ ] All 4 platform builds complete successfully
- [ ] 12+ assets uploaded to desktop release
- [ ] 1 webapp asset in main release
- [ ] Homebrew formula updated with correct checksums
- [ ] Release notes published with proper links
- [ ] No failed GitHub Actions runs

## 🔗 Important Links

### Repositories
- **Main**: https://github.com/happenings-community/requests-and-offers
- **Desktop**: https://github.com/happenings-community/requests-and-offers-kangaroo-electron  
- **Homebrew**: https://github.com/happenings-community/homebrew-requests-and-offers

### Monitoring
- **Actions**: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions
- **Releases**: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/releases

### Documentation
- **Main README**: ../requests-and-offers/README.md
- **Kangaroo Docs**: https://github.com/holochain/kangaroo-electron

## 🎯 Best Practices

### Before Deployment
1. **Test Locally**: Always test the full application locally first
2. **Review Changes**: Check all commits since last release
3. **Validate Configuration**: Run pre-deployment script
4. **Prepare Release Notes**: Have comprehensive notes ready

### During Deployment  
1. **Monitor Actively**: Watch builds in real-time
2. **Document Issues**: Note any problems for future improvement
3. **Verify Assets**: Check that all files upload correctly
4. **Test Installation**: Verify Homebrew and direct downloads work

### After Deployment
1. **Validate All Platforms**: Test installation on Windows, macOS, Linux
2. **Update Documentation**: Keep deployment docs current
3. **Gather Feedback**: Note any user-reported issues
4. **Plan Next Release**: Document lessons learned

## 📝 Deployment Checklist Template

Use this checklist for each deployment:

### Pre-Deployment
- [ ] All tests passing locally
- [ ] Production bootstrap URL configured
- [ ] Version numbers synchronized
- [ ] Release notes prepared
- [ ] Pre-deployment script passes

### Deployment
- [ ] Webapp deployed successfully
- [ ] All platform builds triggered
- [ ] Build monitoring shows success
- [ ] Assets uploaded correctly
- [ ] Homebrew formula updated

### Post-Deployment
- [ ] Direct downloads tested
- [ ] Homebrew installation tested
- [ ] Release notes published
- [ ] Documentation updated
- [ ] Team notified of release

---

**Need Help?** Check the troubleshooting section above or review the logs from failed builds.