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

- `OpenCameraIntent.perform()` (in `AppIntent.swift`) calls
  `NavigationManager.shared.navigate(to: .camera)` and sets
  `openAppWhenRun = true`, which foregrounds the app straight into the camera tab.
  Because `openAppWhenRun` is set, `perform()` runs in the *app's* process, so
  `NavigationManager.shared` is the app's live singleton rather than a short-lived
  copy inside `widgetExtension`.
- Three surfaces mount that one intent: `widgetControl.swift` (a `ControlWidget` for
  Control Center, the Lock Screen's bottom-corner slots and the Action button),
  `widgetAccessory.swift` in its `.camera` mode (a `Button(intent:)` in the Lock Screen
  widget area), and `BatagorAppShortcuts` (an `AppShortcut`, so it's invokable via
  Siri/Shortcuts). `ShortcutManager` handles the equivalent quick-action path when
  launched from a Home Screen long-press.
- Every accessory mode also carries a `.widgetURL` — `batagor://camera` for `.camera`,
  `batagor://gallery` for the read-only modes — so a tap routed as a widget-URL open
  instead of an intent still lands somewhere sensible via
  `batagorApp.handleDeepLink(_:)`.

## Registered widgets

`widgetBundle` registers three widgets:

- `widget` — the Home Screen gallery/timer glance, in three sizes
  (`SmallWidgetView`, `MediumWidgetView`, `LargeWidgetView`, falling back to
  `EmptyWidgetView` when there's no media). Thumbnails are loaded via
  `StorageManager.loadUIImage(fileURL:)` and resized down for the widget rather than
  loading full-resolution photos.
- `widgetAccessory` — the Lock Screen widget, in `.accessoryCircular`,
  `.accessoryRectangular` and `.accessoryInline`.
- `widgetControl` — the Control Center / Lock Screen–corner camera shortcut.

## The accessory widget's three modes

`widgetAccessory` is a single gallery entry backed by `AppIntentConfiguration`, not
three separate widgets. `AccessoryConfigurationIntent` exposes one `AccessoryMode`
parameter (`.camera`, `.timeLeft`, `.count`), so the user long-presses ▸ *Edit Widget*
to switch what it shows. Adding a fourth readout means a new `AccessoryMode` case and
a view, not a new `Widget` registration.

### Why it doesn't reuse `Provider`

`AccessoryProvider` fetches only what the accessory views need — the newest and oldest
surviving `expiredAt`, plus a count — and never touches `thumbnailPath`, so it skips
the `StorageManager.loadUIImage` decodes `Provider` does on every refresh.

More importantly it does **not** copy `Provider`'s `.after(1 minute)` policy. Home
Screen and Lock Screen widgets from the same extension share one refresh budget
(roughly 40–70 reloads/day for the whole app), so a second minute-by-minute timeline
would starve the Home Screen widget. Instead the countdown and gauge views update
themselves on screen:

- `.timeLeft` renders `Text(timerInterval:countsDown:)` / `ProgressView(timerInterval:)`,
  which tick without any reload.
- `.count` renders a `Gauge`, which only changes when media does — and the app already
  pushes those changes via `WidgetCenter.shared.reloadAllTimelines()`.

That leaves the reload policy covering just the one event nothing else announces — a
snap expiring: `.after(latestExpiry)` for `.timeLeft`, `.after(earliestExpiry)` for
`.count` (the count drops when the *oldest* survivor goes), and `.never` for `.camera`.

Trade-off worth knowing: `Text(timerInterval:)` renders `23:59:12` and can't be made to
use `TimeFormatter.formatTimeRemaining`'s compact `23h`. Live ticking and the house
format are mutually exclusive; the accessory widget takes live ticking, the Home Screen
widget keeps `23h`.

### Rendering constraints

The accessory views can't reuse the Home Screen ones. Lock Screen widgets render in
`WidgetRenderingMode.accented` or `.vibrant`, not `.fullColor` — the brand gradient,
`Color.blue70` and photo thumbnails all collapse to a single tint there. So the
accessory views stay with SF Symbols plus short text, mark the tinted elements with
`.widgetAccentable()`, and use `AccessoryWidgetBackground()` rather than the
`.containerBackground(.fill.tertiary,...)` the Home Screen widget uses.
