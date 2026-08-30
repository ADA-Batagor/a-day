# A Day (batagor) — Agent Rules

Detailed rules for any AI coding agent working in this repo. `CLAUDE.md` is a thin
pointer to this file — edit rules here, not there.

## After every code change

There is no lint/format tool configured in this repo (no `.swiftlint.yml` /
`.swiftformat` present — don't invent one or assume it exists).

- **Build** the target(s) you touched before calling a change done:
  `xcodebuild build -project batagor.xcodeproj -scheme batagor -destination 'generic/platform=iOS Simulator'`
  (swap `-scheme widgetExtension` if you only touched `widget/`). Fix all
  warnings and errors before finishing — `CONTRIBUTING.md`'s PR checklist
  requires both targets build warning-free whenever widget-related code was
  touched.
- **No test target exists yet** (`find . -iname "*Tests*"` turns up nothing) —
  don't fabricate `xcodebuild test` instructions or invent a testing framework
  choice on your own; if a task calls for adding tests, that's a decision to
  raise with the user first (see `Testing` below).
- If you touched anything that changes what's shown in the widget or how media
  data is stored, call `WidgetCenter.shared.reloadAllTimelines()` at the point
  the data changes — this is a PR-checklist requirement, not optional cleanup.

---

## Comments

Default to **no comment** — this mirrors the `///` policy in `CONTRIBUTING.md`,
which is the source of truth; the summary below just saves a round trip.

**Add a `///` doc comment:**
- On every new type in `Core/Services/*` (`*Manager`/`*Service`) and
  `ViewModels/*` — at minimum a one-line summary of what it owns/does.
- On every new type in `Models/*` (`@Model` types, shared structs/enums) — same,
  plus any computed property that carries real logic (not a plain stored value).
- On any method or property whose behavior isn't obvious from its name and
  signature alone — side effects (widget reloads, background task
  registration), "why does this run more than once," non-obvious ordering, etc.
  A tricky private helper gets a plain `//` note even though it won't get a
  `///`.

**Skip it:**
- SwiftUI `View` structs — self-explanatory from name + body.
- Plain stored properties with obvious names/types (`var id: UUID`).
- One-off `Extensions/*` helpers (`Color+Ext`, `Font+Ext`) unless the mapping
  itself is non-obvious.

**Known limitation:** `///` comments show up in Xcode's Quick Help regardless of
access level, but only render on the built DocC site for `public`/`open`
symbols. This codebase intentionally stays `internal` everywhere (no external
consumer), so a `///` today buys Quick Help, not a doc-site page — that's an
accepted trade-off, not a bug. Don't mark things `public` just to get DocC
pages; that cascades into unrelated access-control changes.

When editing existing code, leave its comment density as you found it.

---

## Project Structure

```
batagor/
├── batagor/                     # Main app target
│   ├── AppDelegate.swift        # App-wide lifecycle delegation
│   ├── batagorApp.swift         # SwiftUI App entry point
│   ├── Core/
│   │   ├── Helpers/             # Stateless utility structs (Formatter/Manager)
│   │   └── Services/            # Device wrappers & business-logic services,
│   │                             #   grouped by subsystem: Camera/, Location/,
│   │                             #   Storage/, System/
│   ├── Extensions/               # Foundation/SwiftUI type extensions
│   ├── Models/                   # SwiftData @Model entities & plain data models
│   ├── ViewModels/                # MVVM ViewModel layer
│   ├── Views/                     # SwiftUI views, grouped by module
│   │   ├── Camera/, Gallery/, Detail/   # each with a Components/ subfolder
│   │   └── Shared/                      # reusable UI components
│   ├── Documentation.docc/        # Architecture/behavior reference (see below)
│   └── Resources/                 # Assets, Fonts, plists
└── widget/                        # Home Screen widget extension target
```

- `Core/Helpers/`: pure, stateless structs with static methods (formatting,
  transformations). No singletons.
- `Core/Services/`: manager/service classes that wrap hardware/system APIs or
  own business logic, organized into subsystem subfolders (`Camera/`,
  `Location/`, `Storage/`, `System/`). Add a new subsystem subfolder rather than
  dropping a file straight into `Core/Services/`.
- `Views/<Module>/Components/`: view components used only within that module go
  in a `Components/` subfolder next to the module's top-level view — don't
  promote a component to `Views/Shared/` until a second module needs it.
- The two targets (`batagor`, `widgetExtension`) use Xcode's file-system
  synchronized groups (`PBXFileSystemSynchronizedRootGroup`) — a new file dropped
  into `batagor/` or `widget/` on disk is picked up automatically; you don't
  need to manually add it to `project.pbxproj`. The only thing to watch is
  target *membership exceptions* for files shared/excluded between targets
  (see the `PBXFileSystemSynchronizedBuildFileExceptionSet` entries in
  `project.pbxproj` if a file needs to belong to the other target too).

---

## Naming Conventions

| Thing                     | Convention                                   | Example                                  |
| -------------------------- | --------------------------------------------- | ----------------------------------------- |
| Helpers (`Core/Helpers/`)  | `*Formatter` / `*Manager` suffix, static funcs | `TimeFormatter`, `FontManager`            |
| Managers (`Core/Services/`) | `*Manager`, `ObservableObject`, `static let shared` | `LocationManager`, `CameraManager`, `NavigationManager`, `HapticManager` |
| Services (`Core/Services/`) | `*Service`, plain singleton (`static let shared`), not `ObservableObject` unless UI-bound | `DeletionService`, `ModelContainerService` |
| ViewModels (`ViewModels/`) | `*ViewModel`, `ObservableObject` + `@MainActor` | `CameraViewModel`                         |
| Views (`Views/`)           | `*View` suffix (concise entry points may drop it, e.g. `Camera`) | `GalleryView`, `GalleryItemView` |
| Models (`Models/`)         | SwiftData `@Model` classes / plain structs & enums | `Storage`, `PlacemarkInfo`, `FlashCycle` |

---

## Documentation

Two separate docs live side by side and don't repeat each other:

- **`README.md`** — project structure and naming conventions (source of truth;
  this file's "Project Structure"/"Naming Conventions" sections summarize it).
- **`batagor/Documentation.docc/`** — architecture and internal data flow/behavior.
  Built via `Product ▸ Build Documentation` in Xcode locally, or
  `xcodebuild docbuild -project batagor.xcodeproj -scheme batagor -destination 'generic/platform=iOS'`
  (see `.github/workflows/docs.yml`, which publishes it to GitHub Pages on push
  to `main`).

**When you make an architecture-affecting change** (new subsystem, changed data
flow between existing ones), update the relevant DocC article
(`Documentation.docc/Architecture.md`, `AppLifecycle.md`, `CameraPipeline.md`,
`StorageAndDeletion.md`, `WidgetIntegration.md`, `LocationAndGeocoding.md`) in
the **same PR** — don't let it drift to a follow-up.

`Documentation.docc/Tutorials/` is a periodically-refreshed onboarding aid, not
a living reference — keep it roughly accurate, but it doesn't need to track
every change.

---

## Local setup & signing

The app and widget share media through an App Group tied to a signing team, so
each developer needs their own bundle identifier/App Group/team rather than the
committed team default (`com.fuad.batagor`). This is driven by a gitignored
`Config/Local.xcconfig` (copy `Config/Local.xcconfig.template` and fill in your
`BUNDLE_ID_SUFFIX`/`DEVELOPMENT_TEAM`) — see `CONTRIBUTING.md` and `README.md`
for the full walkthrough, including the still-manual step of adding/selecting
the matching App Groups capability in Xcode for your own Apple Developer
account. Never hand-edit `PRODUCT_BUNDLE_IDENTIFIER`/`DEVELOPMENT_TEAM` directly
in `project.pbxproj`, and never commit a personal value there — that's exactly
what `Config/Local.xcconfig` exists to avoid.

---

## Testing

There is currently no test target or `Tests/` folder in this project — device
testing (camera, location) is done manually per the PR checklist below. Don't
add an `XCTest` target, testing library, or test files speculatively; if a task
genuinely calls for automated tests, raise the framework/scope choice with the
user before adding one; do not assume XCTest, Swift Testing, or any project
structure for it.

---

## Branching, PRs & Labels

Trunk-based development: all work merges into `main` via short-lived feature
branches (a few days max — split into smaller PRs if a branch is growing).

| Branch prefix | Use for |
|---|---|
| `feature/` | New features |
| `fix/` | Bug fixes |
| `chore/` | Non-functional changes (deps, config, docs) |

PRs target `main`, reference their Linear issue(s) (see below), stay scoped to
one issue, and must be tested on a physical device before review (the simulator
can't test camera or location). PR checklist:
- [ ] Tested on device
- [ ] No debug code or leftover `print` statements
- [ ] Both `batagor` and `widget` targets build without warnings if
      widget-related code was touched
- [ ] `WidgetCenter.shared.reloadAllTimelines()` called if media data was modified
- [ ] Docs updated if architecture/module structure changed

Labels: `bug`, `feature`, `improvement`, `documentation`, `testing`,
`area: camera`, `area: gallery`, `area: widget`, `area: deletion`.

### Referencing Linear issues

Work is tracked in Linear under `BAT-` keys. The Linear ↔ GitHub integration
resolves a bare `#NN` against **Linear's** numbering, not GitHub's — so
`Closes #41` renders as BAT-41 rather than GitHub issue 41, which is a different
issue entirely. Always reference the `BAT-NN` key; never use `#NN`.

- **Branch** — `<prefix>/bat-<nn>-<slug>`: take the slug from the issue's own
  `gitBranchName` and swap in the right prefix from the table above, e.g.
  `feature/bat-37-tech-liquid-glass-home`. Push under that exact name so Linear
  links the branch to the issue.
- **Commit subject** — Conventional Commits, single line, **no** Linear key and
  no trailers: `type(scope): summary`. The key belongs on the branch and the PR;
  no commit in this repo's history carries one, so adding it now would fork the
  style for no gain.
- **PR title** — `BAT-<nn>: <Human Readable Title>`. When a PR covers more than
  one issue, join them with ` and `:
  `BAT-37: Liquid Glass Home Screen and BAT-54: In-App Settings Screen`.
- **PR description** — mention each bare `BAT-NN` key in the body so Linear
  expands it into a full issue reference. Use a Linear magic word
  (`Closes BAT-54`) only when the PR merging should actually close the issue;
  a plain mention links without transitioning it. Where a GitHub issue also
  exists, link it too — by full URL, never `#NN`.
