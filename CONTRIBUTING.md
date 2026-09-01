# Contributing to batagor

## Local Development Setup

The app and widget share media through an App Group, which is tied to a signing
team — so to run on a physical device, everyone needs their **own** bundle
identifier, App Group, and Team, not the team default (`com.fuad.batagor`,
team `4D8MTY7F2R`). `PRODUCT_BUNDLE_IDENTIFIER`, the App Group entitlement, and
`DEVELOPMENT_TEAM` all resolve from a `BUNDLE_ID_SUFFIX`/`DEVELOPMENT_TEAM` build
setting defined in `Config/Shared.xcconfig`, which in turn optionally includes a
gitignored `Config/Local.xcconfig` — so your personal values live in one local
file that's never committed, instead of being hand-edited into
`project.pbxproj`/`Info.plist`/`.entitlements` on every pull:

```bash
cp Config/Local.xcconfig.template Config/Local.xcconfig
```

Then fill in your own values in `Config/Local.xcconfig`:

```
BUNDLE_ID_SUFFIX = gorengan
DEVELOPMENT_TEAM = YOURTEAMID
```

That's it — no script to re-run, no git hooks to configure, nothing to reset
before committing. `Config/Local.xcconfig` is gitignored, so it survives pulls
and branch switches untouched, and there's no tracked file your personal ID
could accidentally end up in.

You still need to separately add the matching **App Groups** capability entry
in Xcode's Signing & Capabilities for both targets (`group.com.fuad.<your-suffix>`)
— that part registers against your own Apple Developer account and can't be
scripted. See the in-app tutorial (`Documentation.docc/Tutorials`) for the full
walkthrough.

## Branching Strategy

We use **trunk-based development**. All work merges into `main` via short-lived feature branches. Branches should live for no more than a few days — if a branch is growing large, break it into smaller PRs.

## Branch Naming

| Prefix | Use for |
|--------|---------|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Non-functional changes (deps, config, docs) |

Branches carry their Linear issue key: `<prefix>/bat-<nn>-<slug>`, taking the slug from
the issue's own `gitBranchName`. Example: `fix/bat-22-deletion-background-interval`

## Pull Requests

- Title the PR `BAT-<nn>: <Human Readable Title>`, joining multiple issues with ` and `
  (e.g. `BAT-37: Liquid Glass Home Screen and BAT-54: In-App Settings Screen`)
- Reference the Linear issue in the description by its bare key (e.g. `BAT-54`) so Linear
  expands it into a full reference. Where a GitHub issue also exists, link it as well —
  but by full URL, because a bare `#22` resolves against **Linear's** numbering rather
  than GitHub's and will point at the wrong issue
- Keep scope small — one issue per PR
- Test on a physical device before requesting review (simulator cannot test camera or location)
- PRs must target `main`

**PR checklist:**
- [ ] Tested on device
- [ ] No debug code or leftover `print` statements
- [ ] Both `batagor` and `widget` targets build without warnings if widget-related code was touched
- [ ] `WidgetCenter.shared.reloadAllTimelines()` called if media data was modified
- [ ] Docs updated if architecture/module structure changed (see Documentation below)

## Documentation

Technical documentation lives in `batagor/Documentation.docc` (built via
`Product ▸ Build Documentation` in Xcode, or the `docs.yml` workflow on push to
`main`). Project structure and naming conventions stay in this repo's `README.md` —
the DocC catalog covers architecture and behavior instead.

- **Architecture-affecting change** (new subsystem, changed data flow between
  existing ones): update the relevant article under `Documentation.docc` in the same
  PR — don't let it drift to a follow-up.
- **Tutorials** (`Documentation.docc/Tutorials`) are a periodically-refreshed
  onboarding aid, not living reference docs — they don't need to track every change,
  just stay roughly accurate.

### When to add a `///` comment

**Add one:**
- On every new type in `Core/Services/*` (`*Manager`/`*Service`) and `ViewModels/*`
  — at minimum a one-line summary of what it owns/does.
- On every new type in `Models/*` (`@Model` types, shared structs/enums) — same,
  plus any computed property that carries real logic (not a plain stored value).
- On any method or property whose behavior isn't obvious from its name and
  signature alone — side effects (widget reloads, background task registration),
  "why does this run more than once," non-obvious ordering, etc. This applies
  regardless of type — a tricky private helper deserves a plain `//` note even
  though it won't get a `///`.

**Skip it:**
- SwiftUI `View` structs — self-explanatory from name + body.
- Plain stored properties with obvious names/types (`var id: UUID`).
- One-off `Extensions/*` helpers (`Color+Ext`, `Font+Ext`) unless the mapping
  itself is non-obvious.

**Known limitation, so nobody's surprised later:** `///` comments show up in
Xcode's Quick Help (⌥-click) regardless of access level — that works today for
everything documented so far. They do **not** appear in the built DocC website
unless the symbol is `public`/`open`, and this codebase intentionally keeps
everything at the default `internal` access level (there's no external consumer
to design a public API surface for, and marking things `public` cascades into
unrelated access-control changes). So right now, writing a `///` comment gets you
Quick Help, not a rendered page on the doc site — that's an accepted trade-off,
not a bug, unless the team decides the generated symbol pages are worth revisiting.

## Labels

| Label | When to use |
|-------|-------------|
| `bug` | Something is broken |
| `feature` | New capability |
| `improvement` | Enhancement to existing behavior |
| `documentation` | Docs and contributor guides |
| `testing` | Unit or integration tests |
| `area: camera` | Camera capture flow |
| `area: gallery` | Gallery and media browsing |
| `area: widget` | Home screen widget |
| `area: deletion` | Auto-deletion and cleanup |
