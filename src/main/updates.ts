import fs from 'fs';
import path from 'path';

/**
 * The installed app offers an update only when it is the release marked Latest on the wrapper's repository.
 *
 * The updater (@matthme/electron-updater 6.3.0-alpha.1, `out/providers/GitHubProvider.js`) picks the highest tag in the
 * repository's `releases.atom` whose breaking version matches the installed one, and never reads the Latest or prerelease
 * flag; `allowPrerelease` only chooses the channel file it downloads. So the Latest rule is checked here, against the
 * GitHub API, before the user is asked. A draft release is in neither the feed nor `releases/latest`.
 */

/** `owner/repo` from the app-update.yml electron-builder writes into the packaged app's resources, or null. */
export function updateRepository(appUpdateYml: string): string | null {
  const value = (key: string) => {
    const m = new RegExp(`^${key}:\\s*['"]?([^'"\\s]+)['"]?\\s*$`, 'm').exec(appUpdateYml);
    return m ? m[1] : null;
  };
  if (value('provider') !== 'github') return null;
  const owner = value('owner');
  const repo = value('repo');
  return owner && repo ? `${owner}/${repo}` : null;
}

/** The version of a GitHub release tag (`v0.6.0-alpha.2` gives `0.6.0-alpha.2`). */
export const tagVersion = (tag: string): string => tag.replace(/^v/, '');

/**
 * The version of the release marked Latest on the repository the app updates from, or null when it cannot be read:
 * no app-update.yml, another provider, a network error or a timeout. Null means no update is offered.
 */
export async function latestReleaseVersion(timeoutMs = 5000): Promise<string | null> {
  try {
    const yml = fs.readFileSync(path.join(process.resourcesPath, 'app-update.yml'), 'utf8');
    const repository = updateRepository(yml);
    if (!repository) return null;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(`https://api.github.com/repos/${repository}/releases/latest`, {
        headers: { Accept: 'application/vnd.github+json' },
        signal: controller.signal,
      });
      if (!response.ok) return null;
      const release = (await response.json()) as { tag_name?: unknown };
      return typeof release.tag_name === 'string' ? tagVersion(release.tag_name) : null;
    } finally {
      clearTimeout(timer);
    }
  } catch (e) {
    console.warn('Could not read the latest release: ', e);
    return null;
  }
}
