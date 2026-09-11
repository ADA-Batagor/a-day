# `ci_scripts/` — Xcode Cloud hooks

Xcode Cloud automatically runs any script it finds here at fixed points in a
build. The scripts are the **only** part of an Xcode Cloud setup that lives in
the repo — the workflow itself (triggers, actions, TestFlight distribution) is
configured in App Store Connect / Xcode and stored server-side.

| Script | When it runs |
|---|---|
| `ci_post_clone.sh` | Right after the repo is checked out, before package resolution |
| `ci_pre_xcodebuild.sh` | Before each `xcodebuild` invocation (not present — add if needed) |
| `ci_post_xcodebuild.sh` | After each `xcodebuild` invocation (not present — add if needed) |

## What's set up

- **`ci_post_clone.sh`** stamps `CURRENT_PROJECT_VERSION` in
  `Config/Version.xcconfig` with Xcode Cloud's `$CI_BUILD_NUMBER` so every
  TestFlight upload of **A Day (Beta)** gets a unique, increasing build number
  with no manual bump. `MARKETING_VERSION` is untouched. The edit is on the CI
  checkout only — never committed. Running it locally is a safe no-op.

## The Xcode Cloud workflow (configure once, in App Store Connect)

**Prerequisite:** the app record for bundle ID `com.fuad.batagor.beta` must
already exist in App Store Connect, with at least one Internal Testing group
under its TestFlight tab. The TestFlight post-action can't target an app that
doesn't exist yet.

1. Xcode ▸ Product ▸ Xcode Cloud ▸ Create Workflow — pick the **`batagor-beta`**
   scheme.
2. **Start Condition:** Branch Changes → `main`.
3. **Action → Archive - iOS:**
   - Platform: `iOS`, Scheme: `batagor-beta`
   - **Distribution Preparation: `App Store`** (not `None`). There is no
     "TestFlight" option on this screen — `App Store` is what signs the build
     for App Store Connect; TestFlight delivery is a separate post-action.
4. **Post-Actions → `+` → TestFlight Internal Testing.** Select the internal
   tester group(s) that should receive every successful build.
5. Xcode Cloud manages its own signing — no `ExportOptions.plist` or signing
   secrets needed in the repo.
6. There is no "automatically manage build number" toggle on the Archive
   screen; `ci_post_clone.sh` owns the build number regardless.

See `VERSIONING.md` §8 for how the beta build fits the overall versioning model.
