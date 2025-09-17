#!/bin/bash
# Pre-deployment validation script for Requests & Offers
# Ensures all configurations are correct before deployment

set -e

echo "🔍 Pre-deployment validation for Requests & Offers"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "error")
            echo -e "${RED}❌ ERROR: $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
            ;;
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}📋 $message${NC}"
            ;;
    esac
}

# Check if we're in the correct directory
if [ ! -f "kangaroo.config.ts" ]; then
    print_status "error" "Not in kangaroo-electron directory. Please run from the kangaroo-electron root."
    exit 1
fi

print_status "info" "Checking kangaroo configuration..."

# Check bootstrap URL configuration
BOOTSTRAP_URL=$(node -p "
try {
    const config = require('./kangaroo.config.ts').default;
    config.bootstrapUrl || 'undefined';
} catch (e) {
    console.error('Error reading config:', e.message);
    process.exit(1);
}
" 2>/dev/null)

if [[ "$BOOTSTRAP_URL" == "undefined" || "$BOOTSTRAP_URL" == "" ]]; then
    print_status "error" "Bootstrap URL not found in kangaroo.config.ts"
    exit 1
fi

if [[ "$BOOTSTRAP_URL" == *"dev-test"* || "$BOOTSTRAP_URL" == *"test"* ]]; then
    print_status "error" "Still using test bootstrap server: $BOOTSTRAP_URL"
    echo "                Expected: https://holostrap.elohim.host/"
    exit 1
fi

if [[ "$BOOTSTRAP_URL" == "https://holostrap.elohim.host/" ]]; then
    print_status "success" "Production bootstrap server configured: $BOOTSTRAP_URL"
else
    print_status "warning" "Unexpected bootstrap server: $BOOTSTRAP_URL"
    echo "                Expected: https://holostrap.elohim.host/"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check signal URL configuration
SIGNAL_URL=$(node -p "
try {
    const config = require('./kangaroo.config.ts').default;
    config.signalUrl || 'undefined';
} catch (e) {
    'undefined';
}
" 2>/dev/null)

if [[ "$SIGNAL_URL" != "wss://holostrap.elohim.host/" ]]; then
    print_status "warning" "Signal URL mismatch: $SIGNAL_URL"
    echo "                Expected: wss://holostrap.elohim.host/"
fi

print_status "info" "Checking version consistency..."

# Validate version consistency across repositories
KANGAROO_VERSION=$(node -p "require('./package.json').version" 2>/dev/null)
if [ -f "../requests-and-offers/package.json" ]; then
    MAIN_VERSION=$(node -p "require('../requests-and-offers/package.json').version" 2>/dev/null)
    if [[ "$KANGAROO_VERSION" != "$MAIN_VERSION" ]]; then
        print_status "error" "Version mismatch!"
        echo "                Kangaroo: $KANGAROO_VERSION"
        echo "                Main: $MAIN_VERSION"
        exit 1
    fi
    print_status "success" "Version consistency verified: $KANGAROO_VERSION"
else
    print_status "warning" "Main repository not found, skipping version check"
fi

print_status "info" "Checking release status..."

# Check for existing release
if command -v gh &> /dev/null; then
    if gh release view "v$KANGAROO_VERSION" >/dev/null 2>&1; then
        print_status "warning" "Release v$KANGAROO_VERSION already exists"
        echo "                This deployment will overwrite existing assets"
        read -p "Continue with overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "success" "Release v$KANGAROO_VERSION does not exist yet"
    fi
else
    print_status "warning" "GitHub CLI not available, skipping release check"
fi

print_status "info" "Checking required files..."

# Check for required files
REQUIRED_FILES=("package.json" "kangaroo.config.ts" ".github/workflows/release.yaml")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "success" "Found: $file"
    else
        print_status "error" "Missing required file: $file"
        exit 1
    fi
done

# Check if pouch has webhapp file
if ls pouch/*.webhapp 1> /dev/null 2>&1; then
    WEBHAPP_FILE=$(ls pouch/*.webhapp | head -1)
    print_status "success" "WebHapp file found: $(basename "$WEBHAPP_FILE")"
else
    print_status "error" "No .webhapp file found in pouch/ directory"
    echo "                Make sure to run the deployment from the main repo first"
    exit 1
fi

print_status "info" "Checking Git status..."

# Check Git status
if git diff --quiet && git diff --cached --quiet; then
    print_status "success" "Working directory is clean"
else
    print_status "warning" "Working directory has uncommitted changes"
    git status --porcelain
    read -p "Continue with uncommitted changes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "release" ]]; then
    print_status "warning" "Not on release branch (currently on: $CURRENT_BRANCH)"
    echo "                Deployment should typically be done from 'release' branch"
fi

echo
echo "=================================================="
print_status "success" "Pre-deployment validation completed successfully!"
echo
echo "📋 Deployment Summary:"
echo "  Version: $KANGAROO_VERSION"
echo "  Bootstrap: $BOOTSTRAP_URL"
echo "  Signal: $SIGNAL_URL"
echo "  Branch: $CURRENT_BRANCH"
echo "  WebHapp: $(basename "$(ls pouch/*.webhapp | head -1)")"
echo
print_status "info" "Ready to proceed with deployment"