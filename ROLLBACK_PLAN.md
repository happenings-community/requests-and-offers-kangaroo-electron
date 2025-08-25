# 🚨 Rollback Plan - macOS Build Fix

## Quick Rollback Commands

### If CI Fails
```bash
# Revert all changes
git checkout main
git branch -D test/macos-build-fix-alpha-6-1
git push origin --delete test/macos-build-fix-alpha-6-1

# Or revert specific files
git checkout main -- templates/electron-builder-template.yml
git checkout main -- package.json
git checkout main -- .github/workflows/release.yaml
rm scripts/prepare-native-deps.js
```

### If Beta Testing Reveals Issues
```bash
# Partial rollback - keep safe changes, revert problematic ones
git revert [specific-commit-hash]
```

### Individual Component Rollback

**Electron Builder Config**:
```bash
git checkout main -- templates/electron-builder-template.yml
npm run write:configs  # Regenerate without enhancements
```

**Package Dependencies**:
```bash
git checkout main -- package.json
npm install  # Restore original dependencies
```

**Build Scripts**:
```bash
# Edit package.json to remove prebuild calls
# Remove "npm run prebuild &&" from build:mac-* scripts
```

**GitHub Actions**:
```bash
git checkout main -- .github/workflows/release.yaml
```

## Incremental Testing Approach

If full implementation fails, test components individually:

### 1. Minimal ASAR Fix Only
```yaml
# electron-builder-template.yml - minimal change
asarUnpack:
  - resources/**
  - "**/@holochain/hc-spin-rust-utils/**"
```

### 2. Add npm rebuild only
```yaml
npmRebuild: true
```

### 3. Add platform dependencies gradually
```json
// package.json - add one at a time
"optionalDependencies": {
  "@holochain/hc-spin-rust-utils-darwin-arm64": "^0.500.0"
}
```

## Alternative Approaches

### Option A: Electron Rebuild
```bash
npm install -g electron-rebuild
# Add to build scripts:
npx electron-rebuild -p @holochain/hc-spin-rust-utils
```

### Option B: Manual Copy
```yaml
# electron-builder.yml
extraResources:
  - from: "node_modules/@holochain/hc-spin-rust-utils"
    to: "hc-spin-rust-utils"
```

### Option C: Prebuilt Binaries
- Download prebuilt native modules
- Include in resources folder
- Load conditionally based on platform

## Safety Checks

### Before Any Rollback:
1. ✅ Backup current test branch
2. ✅ Document what failed and why
3. ✅ Preserve logs from CI/CD
4. ✅ Notify beta testers of changes

### After Rollback:
1. ✅ Verify main branch still builds correctly
2. ✅ Test that rollback doesn't break other platforms
3. ✅ Update issue tracking with lessons learned

## Emergency Contact
- **Immediate Issues**: GitHub Issues
- **Community Questions**: Discord/Community Channels  
- **CI/CD Problems**: Check GitHub Actions logs first

Remember: The original issue (alpha.6) is already broken for macOS users, so any improvement is better than the current state, even if not perfect.