/* eslint-disable @typescript-eslint/no-var-requires */
const rustUtils = require('@holochain/hc-spin-rust-utils');
const path = require('path');
const fs = require('fs');

const webhappDir = fs.readdirSync(path.join(process.cwd(), 'pouch'));
const webhappFilename = webhappDir.find((file) => file.endsWith('.webhapp'));
if (!webhappFilename) throw new Error('No webhapp file found in pouch folder.');
const webhappPath = path.join(process.cwd(), 'pouch', webhappFilename);

const resourcesDir = path.join(process.cwd(), 'resources');
const uiDir = path.join(resourcesDir, 'ui');
// remove existing UI directory
if (fs.existsSync(uiDir)) {
  fs.rmSync(uiDir, { recursive: true });
}
fs.mkdirSync(uiDir, { recursive: true });

// saveHappOrWebhapp is the 0.6-line API. unpackAndSaveWebhapp exists only on the
// 0.700.x line, and reaching for it pulled a Holochain 0.7 dev build in to read a
// Holochain 0.6 manifest, which is what broke the v0.6.0-alpha.1 desktop builds.
Promise.resolve(rustUtils.saveHappOrWebhapp(webhappPath, 'kangaroo', uiDir, resourcesDir)).catch(
  (err) => {
    console.error('Failed to extract webhapp:', err);
    process.exit(1);
  }
);
