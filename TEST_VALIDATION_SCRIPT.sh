#!/bin/bash
set -e

echo "🧪 macOS Build Fix - Linux-Based Validation"
echo "==========================================="

# Test 1: Configuration Generation
echo "📋 Test 1: Configuration Generation"
echo "-----------------------------------"
npm run write:configs
if [ -f "electron-builder.yml" ]; then
    echo "✅ electron-builder.yml generated successfully"
    
    # Check for native module patterns
    if grep -q "hc-spin-rust-utils" electron-builder.yml; then
        echo "✅ Native module patterns found in asarUnpack"
    else
        echo "❌ Native module patterns missing"
        exit 1
    fi
    
    # Check for macOS extraFiles
    if grep -q "darwin-\${arch}" electron-builder.yml; then
        echo "✅ macOS platform-specific files configuration found"
    else
        echo "❌ macOS platform-specific configuration missing"
        exit 1
    fi
else
    echo "❌ electron-builder.yml not generated"
    exit 1
fi

# Test 2: Native Dependencies Script
echo ""
echo "🔧 Test 2: Native Dependencies Script"
echo "------------------------------------"
if [ -f "scripts/prepare-native-deps.js" ]; then
    echo "✅ prepare-native-deps.js exists"
    
    # Test script execution
    if npm run prebuild; then
        echo "✅ Prebuild script executes successfully"
    else
        echo "❌ Prebuild script failed"
        exit 1
    fi
else
    echo "❌ prepare-native-deps.js missing"
    exit 1
fi

# Test 3: Package.json Dependencies
echo ""
echo "📦 Test 3: Package Dependencies"
echo "-------------------------------"
if grep -q "hc-spin-rust-utils-darwin-arm64" package.json; then
    echo "✅ Darwin ARM64 dependency found"
else
    echo "❌ Darwin ARM64 dependency missing"
    exit 1
fi

if grep -q "hc-spin-rust-utils-darwin-x64" package.json; then
    echo "✅ Darwin x64 dependency found"
else
    echo "❌ Darwin x64 dependency missing"
    exit 1
fi

# Test 4: Build Scripts Integration
echo ""
echo "🏗️ Test 4: Build Scripts"
echo "------------------------"
if grep -q "prebuild.*prepare-native-deps" package.json; then
    echo "✅ Prebuild script defined"
else
    echo "❌ Prebuild script missing"
    exit 1
fi

if grep -q "build:mac-arm64.*prebuild" package.json; then
    echo "✅ macOS ARM64 build includes prebuild"
else
    echo "❌ macOS ARM64 build missing prebuild step"
    exit 1
fi

if grep -q "build:mac-x64.*prebuild" package.json; then
    echo "✅ macOS x64 build includes prebuild"
else
    echo "❌ macOS x64 build missing prebuild step"
    exit 1
fi

# Test 5: GitHub Actions Workflow
echo ""
echo "🔄 Test 5: GitHub Actions Workflow"
echo "----------------------------------"
if [ -f ".github/workflows/release.yaml" ]; then
    if grep -q "Install and rebuild native dependencies" .github/workflows/release.yaml; then
        echo "✅ Native dependencies step found in workflow"
    else
        echo "❌ Native dependencies step missing from workflow"
        exit 1
    fi
    
    if grep -q "hc-spin-rust-utils-darwin-" .github/workflows/release.yaml; then
        echo "✅ Platform-specific installation found in workflow"
    else
        echo "❌ Platform-specific installation missing from workflow"
        exit 1
    fi
else
    echo "❌ GitHub workflow file missing"
    exit 1
fi

# Test 6: Homebrew Formula (if available)
echo ""
echo "🍺 Test 6: Homebrew Formula"
echo "---------------------------"
HOMEBREW_FORMULA="../homebrew-requests-and-offers/Casks/requests-and-offers.rb"
if [ -f "$HOMEBREW_FORMULA" ]; then
    if grep -q "hc-spin-rust-utils" "$HOMEBREW_FORMULA"; then
        echo "✅ Native module fix found in Homebrew formula"
    else
        echo "❌ Native module fix missing from Homebrew formula"
        exit 1
    fi
else
    echo "⚠️  Homebrew formula not accessible (may be in separate repo)"
fi

echo ""
echo "🎉 All Linux-based validations PASSED!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Push to test branch and validate CI/CD pipeline"
echo "2. Set up macOS testing with community members"
echo "3. Monitor for any configuration issues"