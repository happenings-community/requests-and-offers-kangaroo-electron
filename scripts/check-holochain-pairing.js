// Fails when the bundled Holochain and the JavaScript packages that talk to it come from
// different Holochain lines. The v0.6.0-alpha.1 desktop builds broke this way: the
// extractor came from the 0.700 line while the conductor was 0.6, and nothing noticed
// until release day (happenings-community/requests-and-offers#260, #261).
//
// @holochain/hc-spin-rust-utils numbers its line after Holochain's minor (0.6xx for 0.6,
// 0.7xx for 0.7). @holochain/client has its own numbering, listed below; add a row when
// a new Holochain minor is adopted.
const fs = require('fs');
const path = require('path');

require('tsx/cjs');

const CLIENT_FOR_HOLOCHAIN = {
  '0.6': '0.20',
  '0.7': '0.21',
};

const kangarooConfig = require(path.join(process.cwd(), 'kangaroo.config.ts')).default;
const holochainVersion = kangarooConfig.bins.holochainVersion;
const [major, minor] = holochainVersion.split('.');
const holochainLine = `${major}.${minor}`;

const installedVersion = (name) => {
  const file = path.join(process.cwd(), 'node_modules', ...name.split('/'), 'package.json');
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')).version : undefined;
};

const problems = [];

const rustUtils = installedVersion('@holochain/hc-spin-rust-utils');
const rustUtilsLine = rustUtils && rustUtils.match(/^0\.(\d)\d\d\./);
if (!rustUtils) {
  problems.push('@holochain/hc-spin-rust-utils is not installed; run yarn first');
} else if (!rustUtilsLine || `0.${rustUtilsLine[1]}` !== holochainLine) {
  problems.push(
    `@holochain/hc-spin-rust-utils ${rustUtils} is not on the Holochain ${holochainLine} line (expected 0.${minor}xx.x)`,
  );
}

const expectedClient = CLIENT_FOR_HOLOCHAIN[holochainLine];
const client = installedVersion('@holochain/client');
if (!expectedClient) {
  problems.push(
    `no @holochain/client line is listed for Holochain ${holochainLine}; add it to scripts/check-holochain-pairing.js`,
  );
} else if (!client) {
  problems.push('@holochain/client is not installed; run yarn first');
} else if (!client.startsWith(`${expectedClient}.`)) {
  problems.push(
    `@holochain/client ${client} does not pair with Holochain ${holochainLine} (expected ${expectedClient}.x)`,
  );
}

if (problems.length > 0) {
  console.error(`Holochain ${holochainVersion} pairing check failed:`);
  for (const problem of problems) console.error(`  - ${problem}`);
  process.exit(1);
}
console.log(
  `Holochain ${holochainVersion}: hc-spin-rust-utils ${rustUtils} and @holochain/client ${client} pair with it.`,
);
