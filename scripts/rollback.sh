#!/bin/bash
# Emergency rollback script for Requests & Offers deployment
# Quickly reverts to a previous working version

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
            echo -e "${PURPLE}🔄 $message${NC}"
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
    echo "Emergency Rollback Script for Requests & Offers"
    echo
    echo "Usage: $0 <previous-version> [options]"
    echo
    echo "Arguments:"
    echo "  previous-version  Version to rollback to (e.g., 0.1.0-alpha.6)"
    echo
    echo "Options:"
    echo "  --force           Skip confirmation prompts"
    echo "  --config-only     Only rollback configuration files"
    echo "  --dry-run         Show what would be done without executing"
    echo "  --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 0.1.0-alpha.6                    # Full rollback with confirmation"
    echo "  $0 0.1.0-alpha.6 --force            # Immediate rollback"
    echo "  $0 0.1.0-alpha.6 --config-only      # Only config files"
    echo "  $0 0.1.0-alpha.6 --dry-run          # See what would happen"
}

# Parse arguments
PREVIOUS_VERSION="$1"
FORCE="false"
CONFIG_ONLY="false"
DRY_RUN="false"

if [ -z "$PREVIOUS_VERSION" ]; then
    show_help
    exit 1
fi

# Parse options
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE="true"
            shift
            ;;
        --config-only)
            CONFIG_ONLY="true"
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

print_section "Emergency Rollback to v$PREVIOUS_VERSION"

if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "DRY RUN MODE - No changes will be made"
fi

if [ "$CONFIG_ONLY" = "true" ]; then
    print_status "info" "CONFIG ONLY MODE - Only configuration files will be reverted"
fi

# Confirmation prompt (unless forced)
if [ "$FORCE" = "false" ] && [ "$DRY_RUN" = "false" ]; then
    echo "⚠️  WARNING: This will rollback the application to v$PREVIOUS_VERSION"
    echo
    echo "This operation will:"
    echo "  - Revert kangaroo.config.ts and package.json"
    echo "  - Trigger new builds with the previous version"
    echo "  - Update Homebrew formula to previous version"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "info" "Rollback cancelled"
        exit 0
    fi
fi

# Step 1: Verify previous version exists
print_section "Step 1: Verifying previous version"
if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would verify that v$PREVIOUS_VERSION exists in git history"
else
    if ! git rev-parse "v$PREVIOUS_VERSION" >/dev/null 2>&1; then
        print_status "error" "Version v$PREVIOUS_VERSION not found in git history"
        print_status "info" "Available versions:"
        git tag --list "v*" | sort -V | tail -10
        exit 1
    fi
    print_status "success" "Version v$PREVIOUS_VERSION found in git history"
fi

# Step 2: Backup current state
print_section "Step 2: Creating backup of current state"
CURRENT_VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "unknown")
BACKUP_BRANCH="rollback-backup-$(date +%Y%m%d-%H%M%S)"

if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would create backup branch: $BACKUP_BRANCH"
    print_status "info" "Would backup current version: $CURRENT_VERSION"
else
    print_status "info" "Creating backup branch: $BACKUP_BRANCH"
    git checkout -b "$BACKUP_BRANCH"
    git checkout release
    print_status "success" "Backup created for version $CURRENT_VERSION"
fi

# Step 3: Revert configuration files
print_section "Step 3: Reverting configuration files"
CONFIG_FILES=("kangaroo.config.ts" "package.json")

for file in "${CONFIG_FILES[@]}"; do
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would revert $file to v$PREVIOUS_VERSION"
    else
        print_status "info" "Reverting $file to v$PREVIOUS_VERSION..."
        if git checkout "v$PREVIOUS_VERSION" -- "$file"; then
            print_status "success" "Reverted $file"
        else
            print_status "error" "Failed to revert $file"
            exit 1
        fi
    fi
done

# Step 4: Commit rollback changes
print_section "Step 4: Committing rollback changes"
if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "Would commit rollback changes"
    print_status "info" "Would push to release branch"
else
    print_status "info" "Committing rollback changes..."
    git add kangaroo.config.ts package.json
    git commit -m "rollback: emergency revert to v$PREVIOUS_VERSION

- Reverted from v$CURRENT_VERSION to v$PREVIOUS_VERSION
- Backup created in branch: $BACKUP_BRANCH
- Emergency rollback performed on $(date)"
    
    print_status "info" "Pushing rollback to release branch..."
    git push origin release
    print_status "success" "Rollback changes pushed"
fi

# Step 5: Update Homebrew formula (if not config-only)
if [ "$CONFIG_ONLY" = "false" ]; then
    print_section "Step 5: Updating Homebrew formula"
    if [ -d "../homebrew-requests-and-offers" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            print_status "info" "Would update Homebrew formula to v$PREVIOUS_VERSION"
        else
            cd ../homebrew-requests-and-offers
            print_status "info" "Updating Homebrew formula to v$PREVIOUS_VERSION..."
            
            # Check if we have a rollback script
            if [ -f "./scripts/revert-to-version.js" ]; then
                node ./scripts/revert-to-version.js "$PREVIOUS_VERSION"
            else
                print_status "warning" "Homebrew rollback script not found"
                print_status "info" "Manual Homebrew formula update required:"
                echo "  1. Edit Casks/requests-and-offers.rb"
                echo "  2. Change version to '$PREVIOUS_VERSION'"
                echo "  3. Update checksums for v$PREVIOUS_VERSION assets"
                echo "  4. Commit and push changes"
            fi
            
            cd ../requests-and-offers-kangaroo-electron
        fi
    else
        print_status "warning" "Homebrew repository not found at ../homebrew-requests-and-offers"
    fi
else
    print_status "info" "Skipping Homebrew update (config-only mode)"
fi

# Step 6: Trigger new builds (if not config-only)
if [ "$CONFIG_ONLY" = "false" ]; then
    print_section "Step 6: Triggering new builds"
    if [ "$DRY_RUN" = "true" ]; then
        print_status "info" "Would trigger new builds for v$PREVIOUS_VERSION"
    else
        print_status "info" "New builds will be triggered automatically by the push"
        print_status "info" "Monitor builds at:"
        echo "  https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions"
        
        # Optional: Start monitoring automatically
        if [ -f "./scripts/monitor-builds.js" ]; then
            read -p "Start monitoring builds now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                node ./scripts/monitor-builds.js "$PREVIOUS_VERSION"
            fi
        fi
    fi
else
    print_status "info" "Skipping build trigger (config-only mode)"
fi

# Step 7: Cleanup and summary
print_section "Rollback Summary"

if [ "$DRY_RUN" = "true" ]; then
    print_status "info" "This was a dry run. To actually rollback, run without --dry-run"
else
    print_status "success" "Rollback completed successfully!"
fi

echo
echo "📋 Rollback Details:"
echo "  Previous Version: $CURRENT_VERSION"
echo "  Rolled Back To: $PREVIOUS_VERSION"
echo "  Backup Branch: $BACKUP_BRANCH"
echo "  Config Only: $CONFIG_ONLY"
echo "  Date: $(date)"
echo

if [ "$DRY_RUN" = "false" ]; then
    echo "🔗 Important Links:"
    echo "  GitHub Actions: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/actions"
    echo "  Release Page: https://github.com/happenings-community/requests-and-offers-kangaroo-electron/releases/tag/v$PREVIOUS_VERSION"
    echo
    
    print_status "info" "Next steps:"
    echo "  1. Monitor GitHub Actions to ensure builds complete"
    echo "  2. Verify assets are available for v$PREVIOUS_VERSION"
    echo "  3. Test application functionality"
    echo "  4. Communicate rollback to team and users"
    echo "  5. Investigate and fix issues that caused the rollback"
    
    print_status "warning" "Recovery information:"
    echo "  - Your previous version is backed up in branch: $BACKUP_BRANCH"
    echo "  - To restore that version: git checkout $BACKUP_BRANCH && git checkout release && git merge $BACKUP_BRANCH"
    echo "  - To delete backup: git branch -D $BACKUP_BRANCH"
fi

print_status "success" "Rollback operation completed! 🔄"