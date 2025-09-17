# Deployment Scripts

Automated deployment tools for Requests & Offers Holochain application.

## 🚀 Quick Start

```bash
# Complete deployment
./deploy.sh 0.1.0-alpha.8

# Test deployment (dry run)  
./deploy.sh 0.1.0-alpha.8 --dry-run

# Emergency rollback
./rollback.sh 0.1.0-alpha.7
```

## 📜 Scripts Overview

### 🔍 `pre-deploy-check.sh`
**Purpose**: Validates configuration before deployment
**Usage**: `./pre-deploy-check.sh`
**Checks**:
- Production bootstrap URL configuration
- Version consistency across repositories
- Required files and Git status
- Existing release conflicts

### 🚀 `deploy.sh`
**Purpose**: Complete automated deployment process
**Usage**: `./deploy.sh <version> [options]`
**Options**:
- `--skip-tests` - Skip running tests
- `--skip-validation` - Skip pre-deployment checks
- `--dry-run` - Show what would be done
**Process**:
1. Pre-deployment validation
2. Main repository updates
3. WebApp deployment
4. Desktop build triggering
5. Build monitoring
6. Homebrew formula updates
7. Final validation

### 📊 `monitor-builds.js`
**Purpose**: Real-time GitHub Actions build monitoring
**Usage**: `node monitor-builds.js <version>`
**Features**:
- Live status updates for all platforms
- Visual progress indicators
- Build duration tracking
- Automatic completion detection
- Error reporting with log suggestions

### 🔄 `rollback.sh`
**Purpose**: Emergency rollback to previous version
**Usage**: `./rollback.sh <previous-version> [options]`
**Options**:
- `--force` - Skip confirmation prompts
- `--config-only` - Only revert configuration files
- `--dry-run` - Show what would be done
**Features**:
- Automatic backup creation
- Configuration file reversion
- Homebrew formula updates
- Build triggering

## 🎯 Typical Workflow

### Normal Deployment
```bash
# 1. Validate setup
./pre-deploy-check.sh

# 2. Deploy new version  
./deploy.sh 0.1.0-alpha.8

# 3. Monitor builds (automatic in deploy.sh)
# Manual: node monitor-builds.js 0.1.0-alpha.8
```

### Emergency Rollback
```bash
# Quick rollback to previous version
./rollback.sh 0.1.0-alpha.7 --force

# Config-only rollback (no new builds)
./rollback.sh 0.1.0-alpha.7 --config-only
```

### Testing/Development
```bash
# Test deployment without changes
./deploy.sh 0.1.0-alpha.8 --dry-run

# Deploy without running tests (faster)
./deploy.sh 0.1.0-alpha.8 --skip-tests
```

## 🔧 Configuration

### Environment Variables
- `NODE_ENV=production` - Enables production validation
- `CI=true` - Enables CI-specific validation

### Required Tools
- Node.js 22+ and Bun
- GitHub CLI (`gh`) authenticated
- Git with repository access

### Repository Structure
Scripts expect this directory layout:
```
parent-directory/
├── requests-and-offers/
├── requests-and-offers-kangaroo-electron/  # (you are here)
└── homebrew-requests-and-offers/
```

## 🚨 Error Handling

### Script Failures
All scripts use `set -e` for fail-fast behavior. If a script fails:

1. **Check the error message** - Scripts provide detailed error info
2. **Review the logs** - Use `gh run view --log-failed` for build failures  
3. **Validate configuration** - Run `./pre-deploy-check.sh`
4. **Manual intervention** - Some issues require manual fixes

### Common Issues
- **Version mismatches**: Run version sync scripts
- **Test server in production**: Update kangaroo.config.ts
- **GitHub CLI auth**: Run `gh auth login`
- **Missing repositories**: Check directory structure

## 📋 Script Maintenance

### Adding New Platforms
1. Update workflow in `.github/workflows/release.yaml`
2. Add platform mapping in `monitor-builds.js`
3. Update documentation in `DEPLOYMENT.md`

### Extending Validation
1. Add checks to `pre-deploy-check.sh`
2. Update configuration validation in `kangaroo.config.ts`
3. Add monitoring for new failure modes

### Performance Optimization
1. Scripts support parallel operations where possible
2. Monitoring uses efficient GitHub API calls
3. Dry-run mode for testing without side effects

## 🔗 Related Documentation

- **[DEPLOYMENT.md](../DEPLOYMENT.md)** - Complete deployment guide
- **[GitHub Actions](.github/workflows/release.yaml)** - Build workflow
- **[Main Repository](../../requests-and-offers/)** - WebApp deployment
- **[Homebrew Repository](../../homebrew-requests-and-offers/)** - Package management

---

**Need Help?** Check the main DEPLOYMENT.md for detailed troubleshooting.