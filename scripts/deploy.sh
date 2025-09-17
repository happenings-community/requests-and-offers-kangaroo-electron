#!/bin/bash
# Comprehensive deployment script for Requests & Offers
# Handles the entire deployment process from validation to completion

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
        "step")
            echo -e "${PURPLE}🚀 $message${NC}"
            ;;
    esac
}

# Function to print section headers
print_section() {
    echo
    echo "=================================================="
    print_status "step" "$1"
    echo "=================================================="
}

# Help function
show_help() {
    echo "Usage: $0 <version> [options]"
    echo
    echo "Arguments:"
    echo "  version       Version to deploy (e.g., 0.1.0-alpha.8)"
    echo
    echo "Options:"
    echo "  --skip-tests      Skip running tests during deployment"
    echo "  --skip-validation Skip pre-deployment validation"
    echo "  --dry-run         Show what would be done without executing"
    echo "  --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 0.1.0-alpha.8"
    echo "  $0 0.1.0-alpha.8 --skip-tests"
    echo "  $0 0.1.0-alpha.8 --dry-run"
}

# Parse arguments
VERSION="$1"
SKIP_TESTS="false"
SKIP_VALIDATION="false"
DRY_RUN="false"

if [ -z "$VERSION" ]; then
    show_help
    exit 1
fi

# Parse options
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS="true"
            shift
            ;;
        --skip-validation)
            SKIP_VALIDATION="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_status "error" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if we're in the correct directory
if [ ! -f "kangaroo.config.ts" ]; then
    print_status "error" "Not in kangaroo-electron directory. Please run from the kangaroo-electron root."
    exit 1
fi

print_section "Starting deployment for version $VERSION"

if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "DRY RUN MODE - No changes will be made"
fi

if [ "$SKIP_TESTS" = "true" ]; then
    print_status "warning" "Tests will be skipped"
fi

if [ "$SKIP_VALIDATION" = "true" ]; then
    print_status "warning" "Pre-deployment validation will be skipped"
fi

# Step 1: Pre-deployment validation
if [ "$SKIP_VALIDATION" = "false" ]; then
    print_section "Step 1: Pre-deployment validation"
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would run: ./scripts/pre-deploy-check.sh"
    else
        if [ -f "./scripts/pre-deploy-check.sh" ]; then
            ./scripts/pre-deploy-check.sh
        else
            print_status "warning" "Pre-deployment script not found, skipping validation"
        fi
    fi
else
    print_status "warning" "Skipping pre-deployment validation"
fi

# Step 2: Update main repository
print_section "Step 2: Updating main repository"
if [ -d "../requests-and-offers" ]; then
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would update main repository with version $VERSION"
    else
        cd ../requests-and-offers
        print_status "info" "Updating changelog..."
        if [ -f "./scripts/deployment/update-changelog.js" ]; then
            node ./scripts/deployment/update-changelog.js "$VERSION"
        else
            print_status "warning" "Changelog update script not found, skipping"
        fi
        
        print_status "info" "Synchronizing version across repositories..."
        if [ -f "./scripts/deployment/sync-version.js" ]; then
            node ./scripts/deployment/sync-version.js "$VERSION"
        else
            print_status "warning" "Version sync script not found, skipping"
        fi
        
        cd ../requests-and-offers-kangaroo-electron
    fi
else
    print_status "warning" "Main repository not found at ../requests-and-offers"
fi

# Step 3: Deploy webapp
print_section "Step 3: Deploying webapp"
if [ -d "../requests-and-offers" ]; then
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would deploy webapp for version $VERSION"
        if [ "$SKIP_TESTS" = "true" ]; then
            print_status "info" "Would skip tests during webapp deployment"
        fi
    else
        cd ../requests-and-offers
        print_status "info" "Deploying webapp..."
        if [ -f "./scripts/deployment/deploy-webapp.js" ]; then
            if [ "$SKIP_TESTS" = "true" ]; then
                node ./scripts/deployment/deploy-webapp.js "$VERSION" --skip-tests
            else
                node ./scripts/deployment/deploy-webapp.js "$VERSION"
            fi
        else
            print_status "warning" "Webapp deployment script not found"
            print_status "info" "Manual webapp deployment may be required"
        fi
        cd ../requests-and-offers-kangaroo-electron
    fi
else
    print_status "warning" "Cannot deploy webapp - main repository not found"
fi

# Step 4: Trigger desktop builds
print_section "Step 4: Triggering desktop builds"
if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would merge main into release and push to trigger builds"
else
    # Ensure we're on release branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "release" ]; then
        print_status "info" "Switching to release branch..."
        git checkout release
    fi
    
    print_status "info" "Merging main into release..."
    git merge main
    
    print_status "info" "Pushing to trigger desktop builds..."
    git push origin release
    
    print_status "success" "Desktop builds triggered!"
fi

# Step 5: Monitor builds
print_section "Step 5: Monitoring builds"
if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would monitor builds until completion"
else
    if [ -f "./scripts/monitor-builds.js" ]; then
        print_status "info" "Starting build monitoring..."
        node ./scripts/monitor-builds.js "$VERSION"
    else
        print_status "warning" "Build monitoring script not found"
        print_status "info" "You can manually monitor builds at:"
        print_status "info" "https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions"
        
        read -p "Press Enter when all builds are complete..."
    fi
fi

# Step 6: Update Homebrew formula
print_section "Step 6: Updating Homebrew formula"
if [ -d "../homebrew-requests-and-offers" ]; then
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would update Homebrew formula checksums for version $VERSION"
    else
        cd ../homebrew-requests-and-offers
        print_status "info" "Updating Homebrew formula..."
        if [ -f "./scripts/update-checksums.js" ]; then
            node ./scripts/update-checksums.js "$VERSION"
        else
            print_status "warning" "Homebrew update script not found"
            print_status "info" "Manual Homebrew formula update may be required"
        fi
        cd ../requests-and-offers-kangaroo-electron
    fi
else
    print_status "warning" "Homebrew repository not found at ../homebrew-requests-and-offers"
fi

# Step 7: Final validation
print_section "Step 7: Final validation"
if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would run final deployment validation"
else
    if [ -f "./scripts/validate-deployment.js" ]; then
        node ./scripts/validate-deployment.js "$VERSION"
    else
        print_status "info" "Final validation script not found, performing manual checks..."
        
        # Basic manual validation
        print_status "info" "Checking if assets are available..."
        if command -v gh &> /dev/null; then
            ASSET_COUNT=$(gh release view "v$VERSION" --json assets --jq '.assets | length' 2>/dev/null || echo "0")
            if [ "$ASSET_COUNT" -gt "0" ]; then
                print_status "success" "Found $ASSET_COUNT assets in release"
            else
                print_status "warning" "No assets found in release (may still be uploading)"
            fi
        fi
    fi
fi

# Summary
print_section "Deployment Summary"
print_status "success" "Deployment process completed!"
echo
echo "📋 Deployment Details:"
echo "  Version: $VERSION"
echo "  Skip Tests: $SKIP_TESTS"
echo "  Skip Validation: $SKIP_VALIDATION"
echo "  Dry Run: $DRY_RUN"
echo
echo "🔗 Important Links:"
echo "  Desktop Release: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/releases/tag/v$VERSION"
echo "  Main Release: https://github.com/happenings-community/requests-and-offers/releases/tag/v$VERSION"
echo "  GitHub Actions: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions"
echo

if [ "$DRY_RUN" = "false" ]; then
    print_status "info" "Next steps:"
    echo "  1. Verify all assets are uploaded correctly"
    echo "  2. Test Homebrew installation: brew install --cask requests-and-offers"
    echo "  3. Test desktop applications on different platforms"
    echo "  4. Update any additional documentation as needed"
else
    print_status "info" "This was a dry run. To actually deploy, run without --dry-run"
fi

print_status "success" "All done! 🎉"