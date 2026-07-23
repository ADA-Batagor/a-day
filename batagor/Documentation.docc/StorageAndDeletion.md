# Storage and Deletion

Where files and records live, and how expired media gets removed.

## Overview

Three `Core/Services/Storage/` types split the responsibility:

- **`ModelContainerService`** owns the single SwiftData `ModelContainer`
  (`static let shared`), backed by `batagor.sqlite` inside the App Group container
  (`ModelContainerService.appGroupIdentifier`, read from the `GroupAppBundleIdentifier`
  Info.plist key). This is the one container both the `batagor` app and
  `widgetExtension` open — it's what makes the widget's data "just work" without any
  IPC.
- **`StorageManager`** (`static let shared`) writes/reads the actual media *files* —
  photos as HEIC, thumbnails as JPEG — into three subdirectories of the same App
  Group container (`Photos/`, `Movies/`, `Thumbnails/`). Movies are written directly
  by `AVCaptureMovieFileOutput` (see <doc:CameraPipeline>) rather than through
  `StorageManager`.
- **`DeletionService`** (`static let shared`) removes expired records: it fetches
  every `Storage` row, filters where `expiredAt < Date()`, deletes the backing files
  via `StorageManager.deleteFile(fileURL:)`, deletes the SwiftData rows, and calls
  `WidgetCenter.shared.reloadAllTimelines()` so the widget picks up the change.

`Storage` (`Models/Storage.swift`) is the SwiftData `@Model`: it stores file URLs
(`mainPath`, `thumbnailPath`), `createdAt`/`expiredAt`, optional GPS fields, and
computed helpers (`isExpired`, `isVideo`, `timeRemaining`). Expiry defaults to 24
hours from `createdAt` unless a custom `expiredAt` interval is passed in.

## When deletion actually runs

`DeletionService` doesn't run on a fixed timer — it's invoked from two places:

- **Background**: `scheduleBackgroundCleanup()` submits a `BGAppRefreshTaskRequest`
  (`BackgroundTasks` framework) that the system runs opportunistically; the app's
  `BGTaskScheduler` handler calls `performCleanup(modelContext:)`.
- **Manual**: `manualDelete(modelContext:storage:)` is called directly when a user
  deletes an item from the gallery/detail view.

Both paths funnel through the same file-then-record deletion order and the same
`WidgetCenter` reload, so there's a single source of truth for "how a `Storage` row
disappears."

## Seeding

`PhotoSeederService` inserts three dummy `Storage` rows with short expiry windows
(10s/30s/60s) — a debug/preview aid for exercising the countdown and deletion flow
without waiting 24 hours. Skips seeding if any `Storage` rows already exist.
