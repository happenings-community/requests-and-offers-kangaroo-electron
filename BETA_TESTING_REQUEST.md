# 🧪 Beta Testing Request - macOS Build Fix (v0.1.0-alpha.6.1)

## 🎯 What We Need
**macOS users** to test the fix for the native module issue that prevented app launch.

## 🐛 Issue Being Fixed
**Problem**: App crashes on launch with error:
```
Error: Cannot find module '@holochain/hc-spin-rust-utils-darwin-arm64'
```

**Solution**: Enhanced native module packaging and installation process.

## 📋 Testing Instructions

### For CI-Built DMGs (Recommended)
1. Download test DMG from GitHub Actions artifacts:
   - **ARM64 Macs**: Download `*-arm64.dmg`
   - **Intel Macs**: Download `*-x64.dmg`
2. Install the app normally
3. Launch and verify it starts without native module errors
4. Test basic functionality (create request/offer)

### For Homebrew Users  
1. **Uninstall current version**:
   ```bash
   brew uninstall --cask requests-and-offers
   ```

2. **Add test tap** (when ready):
   ```bash
   brew tap happenings-community/requests-and-offers
   brew install --cask requests-and-offers
   ```

3. **Launch and test**

## ✅ Testing Checklist

### Installation
- [ ] DMG mounts without issues
- [ ] App installs to Applications folder
- [ ] No quarantine warnings (should be handled automatically)

### Launch
- [ ] App launches without JavaScript errors
- [ ] No native module error messages
- [ ] Main window appears correctly
- [ ] Loading process completes

### Basic Functionality  
- [ ] Can create a new request
- [ ] Can create a new offer
- [ ] Settings panel loads
- [ ] App doesn't crash during basic usage

### System Compatibility
- [ ] **macOS Version**: _____ (please specify)
- [ ] **Architecture**: ARM64 (Apple Silicon) / Intel x64
- [ ] **Memory usage reasonable** (check Activity Monitor)

## 📊 Feedback Format
Please report using this template:

```markdown
## Test Results

**System**: macOS [version] on [ARM64/Intel]
**Installation Method**: DMG / Homebrew
**Status**: ✅ SUCCESS / ❌ FAILED

### Installation
- Status: [SUCCESS/FAILED]
- Issues: [describe any problems]

### Launch  
- Status: [SUCCESS/FAILED]
- Error messages: [paste any errors]

### Basic Functionality
- Status: [SUCCESS/FAILED] 
- Notes: [any issues or observations]

### Additional Notes
[Any other observations]
```

## 🎯 Success Criteria
- ✅ App launches without native module errors
- ✅ No regression in existing functionality  
- ✅ Installation process smooth for users
- ✅ Performance remains acceptable

## 📅 Testing Timeline
- **Test Branch**: Ready now
- **CI Validation**: Within 24 hours
- **Community Testing**: 2-3 days
- **Release Decision**: Based on feedback

## 🙏 How to Help
1. **Test the fix** using instructions above
2. **Report results** in Discord/GitHub issues
3. **Share with other macOS users** in the community
4. **Provide detailed feedback** on any issues

Thank you for helping make Requests & Offers more reliable for macOS users! 🚀