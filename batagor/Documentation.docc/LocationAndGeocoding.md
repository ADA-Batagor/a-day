# Location and Geocoding

How captured media gets tagged with where it was taken.

## Overview

Two `Core/Services/Location/` types split coordinate tracking from turning a
coordinate into a place name:

- **`LocationManager`** wraps `CLLocationManager`. `CameraViewModel` calls
  `requestPermission()` on init and `startUpdatingLocation()` once authorized (see
  `CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:)`); the latest
  fix is published as `currentLocation`. It also embeds coordinates into finished
  media: `addLocationToVideo(at:location:)` writes QuickTime location metadata into a
  recorded movie file (used by `CameraViewModel.handleSaveMovie`);
  `addLocationToImage(_:location:)` does the equivalent EXIF embedding for a `UIImage`
  but isn't currently called from anywhere — photos get their coordinate stored on
  the `Storage` record instead (see below), not embedded in the file.
- **`GeocodeManager`** (`@MainActor`) turns a coordinate into a human-readable
  `PlacemarkInfo` via `CLGeocoder.reverseGeocodeLocation(_:)`, publishing the result
  as `placemarkInfo`. It also has an unused `searchForBuilding(coordinate:)` path
  that ranks nearby `MKLocalSearch` points of interest — currently commented out in
  `reverseGeocode(coordinate:)` ("Inconsistency accurate building location"), so only
  the plain `CLGeocoder` path runs today.

`PlacemarkInfo` (`Models/PlacemarkInfo.swift`) is a plain struct built from either a
`CLPlacemark` or an `MKPlacemark`, with a `displayName` that falls back through
name → thoroughfare → subLocality → locality → areas of interest → `"Unknown Location"`.

## How a save picks up location + place name

`CameraViewModel.storeLocation(storage:)` runs during both `handleSavePhoto` and
`handleSaveMovie`, after the `Storage` row's coordinate fields are already set from
`locationManager.currentLocation`:

```
storeLocation(storage:)
  guard let location = locationManager.currentLocation
  → geocodeManager.reverseGeocode(coordinate: location.coordinate)
  → storage.locationName = geocodeManager.placemarkInfo?.displayName
  → storage.locationCity = geocodeManager.placemarkInfo?.locality
  → geocodeManager.reset()
```

`GeocodeManager` is reset after every save so stale `placemarkInfo` from a previous
capture never leaks into the next one — each `CameraViewModel` owns one
`GeocodeManager` instance for its whole lifetime, not one per capture.
