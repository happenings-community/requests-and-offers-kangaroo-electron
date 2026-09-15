import { defineConfig } from './src/main/defineConfig';

export default defineConfig({
  appId: 'requests-and-offers.happenings-community.kangaroo-electron',
  productName: 'Requests and Offers',
  version: '0.6.0-alpha.1',
  macOSCodeSigning: false,
  windowsEVCodeSigning: false,
  fallbackToIndexHtml: true,
  autoUpdates: true,
  systray: true,
  passwordMode: 'password-optional',
  networkSeed: 'alpha-test-2026',
  bootstrapUrl: 'https://dev-test-bootstrap2.holochain.org/',
  signalUrl: 'wss://dev-test-bootstrap2.holochain.org/',
  iceUrls: ['stun:stun.cloudflare.com:3478', 'stun:stun.l.google.com:19302'],
  bins: {
    holochainVersion: '0.6.1',
    holochainFeature: 'go-pion',
    holochain: {
      sha256: {
        'x86_64-unknown-linux-gnu':
          'e9c80702e68cbb35612d5ebe9ebb8eb5a35f1724c632f038f323c29c34618600',
        'aarch64-unknown-linux-gnu':
          '10a66f83ac2f7068e291ae1cf64f4c7571d1908ed7403ec08c2e5b92f17a3c15',
        'x86_64-pc-windows-msvc.exe':
          'ceb4512b830511fd596810f8b3cf548235106b0a8a7340a5a18eb88544da99d6',
        'x86_64-apple-darwin': 'b99d17dd3dc20b990c73d2c6e25aab4931b0f99fca838d794b609729f677aa71',
        'aarch64-apple-darwin': '08e6519a7d9835dc4b9a3a868f415298d52c5f50d5234d70a20fa9387951aa0b',
      },
    },
    lair: {
      sha256: {
        'x86_64-unknown-linux-gnu':
          '4d13042d70803d9556bad5f2bfcd01e7daf33ee51ced16cd8d2377a321cceed0',
        'aarch64-unknown-linux-gnu':
          '014e8cf91ff60dcf15c835104a69c46ee8387a83662ba1083156e88c4c2877de',
        'x86_64-pc-windows-msvc.exe':
          '2bbb29415da515a3732cb8d3c51fcf933eb2c44605de2036b8671821b5a414a0',
        'x86_64-apple-darwin': '5ec0c1a70b96ccc625efcee3e23f9d054cadccee379101e179eebb225d7b19d7',
        'aarch64-apple-darwin': 'c3312988eb14fcb0ee0d6cba01e8a41601f48c7a69e03135cbd737d0d9ad774d',
      },
    },
  },
});
