# Widget Integration

How the Home Screen widget stays in sync with the app without any explicit
messaging between the two targets.

## Overview

`widgetExtension` and `batagor` are two separate processes, but they share:

- The **App Group container** (`ModelContainerService.appGroupIdentifier`), which
  holds both the SwiftData store (`batagor.sqlite`) and the media files
  `StorageManager` writes to.
- The **same `ModelContainerService.shared`** — the widget's `Provider` opens
  `ModelContainerService.shared.mainContext` directly and runs the same
  `FetchDescriptor<Storage>` queries the app would, rather than receiving pushed
  data.

There is no custom sync code: because both targets point at the same SQLite file in
the same App Group container, a write from the app is immediately visible to any
`ModelContext` the widget opens afterward.

## Refresh flow

```
App writes/deletes a Storage row (CameraViewModel.handleSavePhoto, DeletionService, ...)
  → WidgetCenter.shared.reloadAllTimelines()
      → WidgetKit re-invokes Provider.getTimeline(in:completion:)
          → fetchRecentMedia(limit:) / fetchCountMedia() re-query the shared store
          → GalleryEntry rebuilt, Timeline scheduled
```

`getTimeline` also self-schedules its *next* refresh independent of app activity:
`.after(nextUpdate)`, 1 minute out if there's media, 5 minutes out if empty — so the
countdown shown in the widget keeps advancing even if the app never reopens.

## Widget → app: opening the camera

The reverse direction (widget triggering app behavior) goes through an `AppIntent`,
not the model store:

- `widgetControl.swift` defines a `ControlWidget` button that runs `OpenCameraIntent`.
- `OpenCameraIntent.perform()` (in `AppIntent.swift`) calls
  `NavigationManager.shared.navigate(to: .camera)` and sets
  `openAppWhenRun = true`, which foregrounds the app straight into the camera tab.
- The same intent is also exposed as an `AppShortcut` (`BatagorAppShortcuts`) so it's
  invokable via Siri/Shortcuts, and `ShortcutManager` handles the equivalent
  quick-action path when launched from a Home Screen long-press.

## Rendering

`widgetBundle` registers two widgets: `widget` (the gallery/timer glance, in three
sizes — `SmallWidgetView`, `MediumWidgetView`, `LargeWidgetView`, falling back to
`EmptyWidgetView` when there's no media) and `widgetControl` (the Control Center
camera shortcut). Thumbnails are loaded via `StorageManager.loadUIImage(fileURL:)`
and resized down for the widget rather than loading full-resolution photos.
