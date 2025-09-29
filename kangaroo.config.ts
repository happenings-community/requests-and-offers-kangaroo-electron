import { defineConfig } from './src/main/defineConfig';

const config = defineConfig({
  // Release v0.1.8 with network invite system and simplified versioning
  appId: 'requests-and-offers.happenings-community.kangaroo-electron',
  productName: 'Requests and Offers',
  version: '0.1.8',
  macOSCodeSigning: false,
  windowsEVCodeSigning: false,
  fallbackToIndexHtml: true,
  autoUpdates: false,
  systray: true,
  passwordMode: 'no-password',
  networkSeed: 'alpha-test-2025',
  bootstrapUrl: 'https://holostrap.elohim.host/',
  signalUrl: 'wss://holostrap.elohim.host/',
  iceUrls: ['stun:stun.cloudflare.com:3478', 'stun:stun.l.google.com:19302'],
  bins: {
    holochain: {
      version: '0.5.5',
      sha256: {
        'x86_64-unknown-linux-gnu':
          '8c1e0c6e72fb5dde157973ee280ee494bbbad1926820829339dc67b84bc86b6e',
        'x86_64-pc-windows-msvc.exe':
          'cb62f336c1be9fbf8c4a823b4e6b0248903f8e07c881497c8590e923142bbdaf',
        'x86_64-apple-darwin': '430bc76fa9561461cf038f9ce4939171712ba02ce6eefc4a0aa43ac3496e498c',
        'aarch64-apple-darwin': 'c7535f3ce81cb6a72397d5942da6bb4a16d9eb9afc78af7ce0b861ca237d51f7',
      },
    },
    lair: {
      version: '0.6.2',
      sha256: {
        'x86_64-unknown-linux-gnu':
          '3c9ea3dbfc0853743dad3874856fdcfe391dca1769a6a81fc91b7578c73e92a7',
        'x86_64-pc-windows-msvc.exe':
          '6392ce85e985483d43fa01709bfd518f8f67aed8ddfa5950591b4ed51d226b8e',
        'x86_64-apple-darwin': '746403e5d1655ecf14d95bccaeef11ad1abfc923e428c2f3d87c683edb6fdcdc',
        'aarch64-apple-darwin': '05c7270749bb1a5cf61b0eb344a7d7a562da34090d5ea81b4c5b6cf040dd32e8',
      },
    },
  },
});

// Production deployment validation
// This prevents accidentally deploying with test servers in production
if (process.env.NODE_ENV === 'production' || process.env.CI === 'true') {
  const productionBootstrapUrl = 'https://holostrap.elohim.host/';
  const productionSignalUrl = 'wss://holostrap.elohim.host/';

  if (!config.bootstrapUrl || config.bootstrapUrl !== productionBootstrapUrl) {
    console.error(`
❌ DEPLOYMENT ERROR: Invalid bootstrap server for production!
Current: ${config.bootstrapUrl || 'undefined'}
Expected: ${productionBootstrapUrl}

Please update kangaroo.config.ts to use the production bootstrap server.
    `);
    process.exit(1);
  }

  if (!config.signalUrl || config.signalUrl !== productionSignalUrl) {
    console.error(`
❌ DEPLOYMENT ERROR: Invalid signal server for production!
Current: ${config.signalUrl || 'undefined'}
Expected: ${productionSignalUrl}

Please update kangaroo.config.ts to use the production signal server.
    `);
    process.exit(1);
  }

  // Check for test server patterns
  if (config.bootstrapUrl?.includes('dev-test') || config.bootstrapUrl?.includes('test')) {
    console.error(`
❌ DEPLOYMENT ERROR: Test bootstrap server detected in production!
Current: ${config.bootstrapUrl}
Expected: ${productionBootstrapUrl}

Test servers should not be used in production deployments.
    `);
    process.exit(1);
  }

  // Only log validation success when not being required by scripts
  if (require.main === module) {
    console.log('✅ Production server validation passed');
  }
}

export default config;
