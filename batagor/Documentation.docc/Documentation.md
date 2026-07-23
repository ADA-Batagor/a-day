# ``batagor``

Temporary storage for photos and videos — captures expire and clean themselves up
automatically so they never clutter your camera roll.

## Overview

A Day (product name **batagor**) is a SwiftUI iOS app made up of two targets: the
`batagor` app itself and a `widgetExtension` that shows remaining time/count on the
Home Screen. Both share one SwiftData-backed store through an App Group container, so
a photo taken in the app and its expiry countdown are visible in the widget without
any extra syncing code.

This catalog covers **architecture and internal data flow** — how the pieces fit
together and why. For project setup, folder structure, and naming conventions, see
`README.md` at the repository root; those aren't repeated here.

## Topics

### Essentials

- <doc:Architecture>

### Subsystems

- <doc:CameraPipeline>
- <doc:StorageAndDeletion>
- <doc:WidgetIntegration>
- <doc:LocationAndGeocoding>
