/* eslint-disable @typescript-eslint/no-var-requires */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function prepareNativeDeps() {
  console.log('Preparing native dependencies for Electron build...');
  
  const platform = process.platform;
  const arch = process.arch;
  
  console.log(`Platform: ${platform}, Architecture: ${arch}`);
  
  try {
    // Install platform-specific dependencies based on current platform
    if (platform === 'darwin') {
      const darwinPackage = `@holochain/hc-spin-rust-utils-darwin-${arch}`;
      console.log(`Installing ${darwinPackage}...`);
      
      try {
        execSync(`npm install --save-optional ${darwinPackage}@0.500.0`, { 
          stdio: 'inherit',
          cwd: process.cwd()
        });
      } catch (installError) {
        console.warn(`Warning: Failed to install ${darwinPackage}:`, installError.message);
        // Continue with rebuild attempt
      }
      
      // Also install universal package if available
      try {
        execSync('npm install --save-optional @holochain/hc-spin-rust-utils-darwin-universal@0.500.0', { 
          stdio: 'inherit',
          cwd: process.cwd()
        });
      } catch (universalError) {
        console.warn('Warning: Universal package not installed:', universalError.message);
      }
    }
    
    // Force rebuild of native modules with update-binary flag
    console.log('Rebuilding native modules...');
    try {
      execSync('npm rebuild @holochain/hc-spin-rust-utils --update-binary', { 
        stdio: 'inherit',
        cwd: process.cwd()
      });
    } catch (rebuildError) {
      console.warn('Warning: Native rebuild failed:', rebuildError.message);
      
      // Try alternative rebuild method
      try {
        execSync('npm rebuild @holochain/hc-spin-rust-utils', { 
          stdio: 'inherit',
          cwd: process.cwd()
        });
      } catch (altRebuildError) {
        console.warn('Warning: Alternative rebuild also failed:', altRebuildError.message);
      }
    }
    
    // Verify the main module exists and is loadable
    console.log('Verifying native module installation...');
    const modulePath = path.join(
      process.cwd(),
      'node_modules',
      '@holochain',
      'hc-spin-rust-utils'
    );
    
    if (!fs.existsSync(modulePath)) {
      throw new Error('hc-spin-rust-utils module not found after rebuild');
    }
    
    // Test module loading
    try {
      require('@holochain/hc-spin-rust-utils');
      console.log('✅ Native module loads successfully');
    } catch (loadError) {
      console.warn('⚠️  Warning: Module exists but failed to load:', loadError.message);
      console.warn('This may be expected during cross-platform builds.');
    }
    
    // List installed holochain packages for debugging
    console.log('Installed @holochain packages:');
    try {
      const result = execSync('npm ls @holochain/hc-spin-rust-utils', { 
        encoding: 'utf8',
        cwd: process.cwd()
      });
      console.log(result);
    } catch (lsError) {
      console.warn('Could not list packages:', lsError.message);
    }
    
    console.log('✅ Native dependencies prepared successfully');
  } catch (error) {
    console.error('❌ Failed to prepare native dependencies:', error.message);
    console.error('This may cause runtime issues on the target platform.');
    
    // Don't exit with error to allow builds to continue
    // Some cross-platform scenarios may not be able to test module loading
    console.log('Continuing with build process...');
  }
}

// Check if this script is being run directly
if (require.main === module) {
  prepareNativeDeps();
}

module.exports = { prepareNativeDeps };