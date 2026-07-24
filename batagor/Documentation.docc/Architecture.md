# Architecture

The high-level shape of the app: how Views, ViewModels, Services, and Models compose,
and where the `widgetExtension` target fits in.

## MVVM shape

@Image(source: "architecture-diagram.svg", alt: "Diagram of Views calling into ViewModels, which call the four Core/Services subsystems (Camera, Location, Storage, System), which read and write Models backed by a shared App Group container. widgetExtension reads that same store directly and is notified via WidgetCenter.reloadAllTimelines() after writes.")

- **`Views/`** are SwiftUI structs. They hold no business logic — they bind to a
  `ViewModel` (via `@StateObject`/`@ObservedObject`) or read a shared `Manager`
  directly (via `@EnvironmentObject`) for cross-cutting state like navigation or
  orientation.
- **`ViewModels/`** (currently just `CameraViewModel`) own the state a specific
  screen needs and translate user actions into calls on one or more `Core/Services`
  types. They're `@MainActor` + `ObservableObject` so UI updates are always
  main-thread-safe even though the services underneath do async/background work.
- **`Core/Services/`** is where the actual work happens — see the split below.
- **`Models/`** are the persisted/plain data: `Storage` (a SwiftData `@Model`) and
  `PlacemarkInfo` (a plain struct built from `CLPlacemark`/`MKPlacemark`).

## `Manager` vs `Service`

`Core/Services/` groups by subsystem (`Camera/`, `Location/`, `Storage/`, `System/`),
and within those, types follow one of two shapes:

- **`*Manager`** — stateful, usually `ObservableObject`, usually a
  `static let shared` singleton, wraps a system/hardware API or app-wide UI state.
  Examples: `CameraManager` (AVFoundation), `LocationManager` (CoreLocation),
  `NavigationManager` (tab/detail navigation state), `TimerManager` (a shared
  ticking clock), `OrientationManager` (device attitude via CoreMotion).
- **`*Service`** — a transactional/data operation, not necessarily observable.
  Examples: `DeletionService` (expiry cleanup), `ModelContainerService` (the shared
  SwiftData container), `PhotoSeederService` (debug/preview data).

`CameraViewModel` is the clearest example of composition: it owns a `CameraManager`,
a `LocationManager`, a `GeocodeManager`, and references `StorageManager.shared` and
`OrientationManager.shared`, wiring their async streams into `@Published` properties
the `CameraView` observes.

## Target boundaries

- **`batagor`** (the app) — captures and displays media, owns the SwiftData
  `ModelContext` used for writes.
- **`widgetExtension`** — read-only. It opens the *same* SwiftData store via
  `ModelContainerService.shared` (same App Group container) and renders a
  `TimelineProvider` from it. It never writes; the app calls
  `WidgetCenter.shared.reloadAllTimelines()` after any change so the widget's
  timeline picks it up.

See <doc:CameraPipeline>, <doc:StorageAndDeletion>, <doc:WidgetIntegration>, and
<doc:LocationAndGeocoding> for how each subsystem actually works, and
<doc:AppLifecycle> for where it all gets wired together at startup.
