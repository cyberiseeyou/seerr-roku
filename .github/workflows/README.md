# Workflows

## `ci.yml` — runs on every PR against `main`

Four independent jobs, all required to pass:

- **`lint`** — [`@rokucommunity/bslint`](https://github.com/rokucommunity/bslint) static analysis on the BrightScript source.
- **`security`** — [gitleaks](https://github.com/gitleaks/gitleaks) secret scanning, so a hardcoded credential can't land unnoticed.
- **`test`** — placeholder. There's no automated test framework for BrightScript in use here — verify manually via sideload before merging instead.
- **`build`** — packages the channel (`manifest`, `components/`, `source/`, `images/`) into a zip and uploads it as a PR artifact (`seerr-roku-pr-<number>`), so a reviewer can sideload the exact commit under review without building it themselves.

**Downloading that artifact:** GitHub always wraps a downloaded artifact in an extra outer zip. Since this artifact's content is already a `.zip`, what you download is a zip-of-a-zip — extract it once to get the real, sideloadable `seerr-roku-pr-<number>.zip` before uploading it to a Roku's installer, or you'll get `Install Failure: No manifest. Invalid package.` (`gh run download` extracts this outer layer for you automatically; a browser download does not).

## `release.yml` — runs on a `v*.*.*` tag push

Fully automated once triggered — no input beyond the tag itself:

1. Verifies the tagged commit is actually reachable from `main` (fails loudly otherwise, rather than silently publishing from a side branch).
2. Packages the same zip, named `seerr-roku-<tag>.zip`.
3. Publishes a GitHub Release for that tag with the zip attached and auto-generated release notes.

**This workflow has no human-approval gate of its own** — it publishes the moment a matching tag lands, whether or not anyone actually reviewed the changes first. Pushing a `v*.*.*` tag is what triggers a public release, so treat that push itself as the release decision.
