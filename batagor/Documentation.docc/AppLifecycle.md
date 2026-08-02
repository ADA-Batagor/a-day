# App Lifecycle and Entry Points

Where the app actually starts, and the three different ways something outside the
app can land you on a specific screen.

## The composition root

`batagorApp` (`batagorApp.swift`) is where everything gets wired together — it's the
file to open first when getting oriented:

- Bridges to UIKit via `@UIApplicationDelegateAdaptor(AppDelegate.self)` for the
  parts SwiftUI's lifecycle doesn't cover directly (font registration, cold-launch
  shortcut handling — see below).
- Instantiates the shared singletons as `@StateObject`s (`TimerManager.shared`,
  `NavigationManager.shared`, `ShortcutManager.shared`) and injects
  `ModelContainerService.shared` app-wide via `.modelContainer(_:)`.
- The root `NavigationStack` switches between `Camera()` and `GalleryView()` based on
  `NavigationManager.selectedTab` — there's no `NavigationLink`-driven push stack for
  the two main tabs, just a `switch` bound to published state.
- `.onAppear` runs `DeletionService.performCleanup(modelContext:)` — this is the
  **foreground cleanup path** mentioned in <doc:StorageAndDeletion> — and calls
  `ShortcutManager.processShortcutItem(navigationManager:)` to act on a shortcut that
  triggered a cold launch.
- `.backgroundTask(.appRefresh(DeletionService.backgroundTaskIdentifier))` is where
  `DeletionService`'s background cleanup actually gets registered with the system —
  `DeletionService` itself only *submits requests* via `scheduleBackgroundCleanup()`;
  this modifier is what the OS calls back into, and it's the one that re-arms the
  next request after each run.

## Three ways into a specific screen

Something outside the running app's UI can land the user on a specific tab or media
item through three independent paths, all converging on the same
`NavigationManager` calls:

| Path | Entry point | Where it's handled |
|---|---|---|
| Home Screen long-press shortcut | `UIApplicationShortcutItem` | `AppDelegate`/`SceneDelegate` (cold vs. warm launch) → `ShortcutManager` → `batagorApp` observes it → `NavigationManager` |
| Widget → app (`OpenCameraIntent`) | `AppIntent` (`perform()`) | Calls `NavigationManager.shared.navigate(to:)` directly — see <doc:WidgetIntegration> |
| Deep link (`batagor://…`) | `.onOpenURL` | `batagorApp.handleDeepLink(_:)` → `NavigationManager` |

**Home Screen shortcuts** are the most involved because cold and warm launch are
handled in different places, both funneling into the same `ShortcutManager`:

```
Cold launch (app not running)
  AppDelegate.application(_:configurationForConnecting:options:)
    → ShortcutManager.shared.handleShortcut(_:)

Warm launch (app already running/suspended)
  SceneDelegate.windowScene(_:performActionFor:completionHandler:)
    → ShortcutManager.shared.handleShortcut(_:)

Either way, once shortcutItem is published:
  batagorApp observes it (.onAppear on first launch, .onChange thereafter)
    → ShortcutManager.processShortcutItem(navigationManager:)
      → NavigationManager.navigate(to:)
```

**Deep links** are the simplest — `handleDeepLink(_:)` matches on `URL.host` and
calls `NavigationManager` directly, no intermediate manager involved:

- `batagor://gallery` → `navigate(to: .gallery)`
- `batagor://camera` → `navigate(to: .camera)`
- `batagor://media/<uuid>` → `navigateToMediaDetail(mediaId:)`

**Widget → app** is covered in full in <doc:WidgetIntegration> — it's the one path
that calls `NavigationManager` straight from an `AppIntent`, with no OS-level
indirection to unwind.
