# App Versioning Process

This document defines how we version **A Day** (the `batagor` app target + the `widgetExtension`
widget target), where the version lives, and how a version becomes a shipped release.

## 1. Versioning Scheme

We use **Semantic Versioning (SemVer)**: `MAJOR.MINOR.PATCH`

- **MAJOR** — breaking / incompatible changes (SwiftData migration required, major redesign, etc.)
- **MINOR** — new features, backward-compatible
- **PATCH** — bug fixes, backward-compatible

Reference: https://semver.org/

Bump decisions are made by a human at release-cut time, based on what actually shipped since the
last release (not automated from commit messages).

## 2. Where the Version Lives: `Config/Version.xcconfig`

A single `Config/Version.xcconfig` file is the **source of truth** for both the app and the widget
extension:

```xcconfig
// Config/Version.xcconfig
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

- `MARKETING_VERSION` → `CFBundleShortVersionString` → the SemVer string shown to users
  (App Store, Settings, TestFlight).
- `CURRENT_PROJECT_VERSION` → `CFBundleVersion` → the build number, used internally by
  App Store Connect to disambiguate uploads.

### Shared App Group Version

`batagor` and `widgetExtension` share the App Group `group.com.fuad.$(BUNDLE_ID_SUFFIX)`, so
their versions must never drift. They don't have to be wired up separately:
`Config/Shared.xcconfig` is already the **project-level** base configuration for both `Debug` and
`Release`, and every target inherits from it. Pulling the version in there covers both targets at
once:

```xcconfig
// Config/Shared.xcconfig
BUNDLE_ID_SUFFIX = batagor
DEVELOPMENT_TEAM = 4D8MTY7F2R

#include "Version.xcconfig"
#include? "Local.xcconfig"
```

`Version.xcconfig` is committed (unlike the gitignored `Local.xcconfig`) — it's shared team state,
not a personal signing override.

**One-time prerequisite:** `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are currently set
per-target in `batagor.xcodeproj/project.pbxproj` (4 places: 2 targets × Debug/Release).
Target-level build settings **override** xcconfig values, so those lines must be deleted from the
project file before the xcconfig becomes the source of truth. In Xcode: select each target →
Build Settings → search "version" → select the row → Delete.

### Build Number Reset Rule

`CURRENT_PROJECT_VERSION` resets to `1` every time `MARKETING_VERSION` changes, then increments by
1 for every subsequent build/upload against that same marketing version (bug-fix TestFlight
builds, resubmissions, etc.).

Example:

| MARKETING_VERSION | CURRENT_PROJECT_VERSION | Event                    |
| ----------------- | ----------------------- | ------------------------ |
| 1.0.0             | 1                       | First TestFlight build   |
| 1.0.0             | 2                       | Crash fix, re-uploaded   |
| 1.0.0             | 3                       | App Store submission     |
| 1.1.0             | 1                       | Next release, reset to 1 |

## 3. Where the Release Artifact Lives: Tags + GitHub Releases

We use **tags and GitHub Releases**, not per-version branches.

- `main` always reflects current in-progress code.
- A release is cut by bumping `Config/Version.xcconfig`, committing, and tagging that commit.
- The **git tag** (`v1.0.0`) is the immutable pointer to the exact commit that shipped.
- The **GitHub Release** built from that tag holds the release notes and the built `.ipa`
  as binary attachments (binaries are never committed to git history).

Why tags over branches: branches are mutable/moving and imply ongoing work; a shipped version
should never change after the fact. A tag + release gives us a permanent, auditable snapshot.

## 4. Release Flow

Release commits go through the same PR flow as everything else (see `CONTRIBUTING.md`) — nobody
pushes to `main` directly.

```bash
# 1. Bump the version file on a branch
#    Edit Config/Version.xcconfig: MARKETING_VERSION = 1.1.0, CURRENT_PROJECT_VERSION = 1

git checkout -b chore/bat-XX-release-1.1.0
git add Config/Version.xcconfig
git commit -m "chore: bump version to 1.1.0"
git push -u origin chore/bat-XX-release-1.1.0

# 2. Open a PR for that branch on GitHub, get it reviewed, and merge it to main.

# 3. Tag the merge commit on main
git checkout main && git pull
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin v1.1.0
```

Pushing the tag triggers the release pipeline (below).

For subsequent builds against the same marketing version (bug-fix TestFlight builds before the
App Store release), only bump `CURRENT_PROJECT_VERSION` and repeat steps 1–3 with a build-specific
tag if you want each upload tagged (optional — many teams only tag the final App Store release).

## 5. CI/CD: GitHub Actions

A workflow at `.github/workflows/release.yml`, triggered on tag push, builds the archive, exports
the `.ipa`, and publishes it as a GitHub Release asset. It runs on `macos-15` to match the
existing `docs.yml` workflow.

```yaml
name: Release

on:
  push:
    tags:
      - "v*.*.*"

permissions:
  contents: write

jobs:
  build-and-release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Verify tag matches MARKETING_VERSION
        run: |
          set -euo pipefail
          TAG_VERSION="${GITHUB_REF_NAME#v}"
          FILE_VERSION=$(grep MARKETING_VERSION Config/Version.xcconfig | awk -F'=' '{print $2}' | tr -d ' ')
          if [ "$TAG_VERSION" != "$FILE_VERSION" ]; then
            echo "Tag ($TAG_VERSION) does not match Config/Version.xcconfig ($FILE_VERSION)" >&2
            exit 1
          fi

      - name: Archive
        run: |
          xcodebuild archive \
            -project batagor.xcodeproj \
            -scheme batagor \
            -archivePath build/batagor.xcarchive \
            -destination 'generic/platform=iOS'

      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath build/batagor.xcarchive \
            -exportPath build/ \
            -exportOptionsPlist ExportOptions.plist

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            build/batagor.ipa
          generate_release_notes: true
```

Key points:

- The **tag-vs-file verification step** is a guardrail: it fails the build if someone tags a
  release without bumping `Config/Version.xcconfig`, catching the most common release mistake early.
- Because `Config/Shared.xcconfig` is the project-level base configuration, one archive of the
  `batagor` scheme embeds `widgetExtension` with the same version/build number — no extra CI steps
  needed to sync them, and no separate `-scheme widgetExtension` build.
- `generate_release_notes: true` auto-populates the GitHub Release notes from merged PRs since the
  last tag; edit as needed before publishing.

**Not yet set up:** `archive`/`-exportArchive` need real signing, which the repo doesn't have in CI
today — `Config/Local.xcconfig` (with `DEVELOPMENT_TEAM`) is gitignored, there's no
`ExportOptions.plist`, and no signing secrets are configured on `ADA-Batagor/a-day`. Landing this
workflow means first adding an Apple distribution certificate + provisioning profile as repository
secrets, importing them into a temporary keychain, and committing an `ExportOptions.plist`. Until
then, archives are exported from Xcode manually.

## 6. Handling App Store Rejections

If a submitted build is **rejected** by App Store Review, bump only the **build number**
(`CURRENT_PROJECT_VERSION`) and resubmit — do **not** bump `MARKETING_VERSION`.

Rationale: a rejection means that version never reached users, so there's nothing to communicate
a "fix" against. Bumping the patch version would burn a version number on something users never
experienced and break the clean release progression (e.g. `1.0.1 → 1.1.0`, not
`1.0.1 → 1.1.0 → 1.1.1` for a build that was never live).

```
1.1.0  build 1   → submitted, rejected (crash, metadata issue, etc.)
1.1.0  build 2   → fix applied, resubmitted
1.1.0  build 3   → approved, released
1.1.1  build 1   → next release, resets as normal
```

**Exception:** if the rejection forces a genuinely breaking or user-facing scope change (not just
a fix to pass review), treat it as a new release and bump `MARKETING_VERSION` accordingly. This
should be rare — most rejections are compliance, crash, or metadata issues that don't change what
was intended to ship.

## 7. Quick Reference

| Concept            | Where it lives                                            | Who/what updates it                                      |
| ------------------ | --------------------------------------------------------- | -------------------------------------------------------- |
| SemVer string      | `MARKETING_VERSION` in `Config/Version.xcconfig`          | Human, at release-cut time                               |
| Build number       | `CURRENT_PROJECT_VERSION` in `Config/Version.xcconfig`    | Human, resets to 1 per marketing version, +1 per rebuild |
| Widget version     | Same file, via `Config/Shared.xcconfig` (project-level)   | Automatic (inherited by both targets)                    |
| Release checkpoint | Git tag `vMAJOR.MINOR.PATCH` on `main`                    | Human, after the version-bump PR merges                  |
| Shipped binary     | GitHub Release assets (`.ipa`, `dSYM`) on the tag         | GitHub Actions, on tag push                              |
| Release trigger    | `push: tags: 'v*.*.*'` in `.github/workflows/release.yml` | Automatic                                                |
