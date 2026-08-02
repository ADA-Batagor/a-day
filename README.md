<p align="center">
  <img src="batagor/Resources/Assets.xcassets/AppIcon.appiconset/A%20day-App%20Icon.png" width="128" height="128" style="border-radius: 22%;" alt="A Day App Icon" />
</p>

<h1 align="center">A Day</h1>

<p align="center">
  <strong>Temporary storage for photos and videos. Prevent digital clutter from filling up your device!</strong>
</p>

<p align="center">
  📖 <a href="https://ada-batagor.github.io/a-day/documentation/batagor/">Technical documentation</a> (architecture, subsystems, symbol reference, tutorial) — also buildable locally via <code>Product ▸ Build Documentation</code> in Xcode.
</p>

---

## 📋 Project Information

**A Day** is an iOS application designed to help users capture and store temporary photos and videos. Instead of cluttering the system library with temporary media (like recipes, parking spot photos, receipts, or quick references), A Day stores them in an isolated, shared sandbox with automatic background deletion once their expiry duration has passed.

### Key Features

- **Temporary Capture**: Quickly capture photos or record videos with customized lifespans.
- **Auto-Cleanup**: Background task schedules automatic removal of expired media assets.
- **Shared Sandboxing**: Securely stores assets using App Groups so that the widget and the main app can read/write the same media library.
- **SwiftData Integration**: Persistent model state synchronization across the main application and its extensions.
- **Interactive Widgets**: View remaining time and count of temporary media assets directly on your Home Screen.

---

## ⚙️ Prerequisites

To build and run A Day, ensure your development environment meets the following requirements:

- **Operating System**: macOS Sonoma (14.0) or later.
- **IDE**: Xcode 15.0 or later.
- **SDK & Runtime**: Swift 5.9+, iOS 18.0 or later.
- **Signing**: An Apple Developer account is required to enable **App Groups** on physical devices (Simulator runs App Groups locally without developer portal registration).

---

## 🛠️ Preparation to Run the Project

Since A Day relies on App Groups to share database records and media assets between the main app and the home screen widget, you need to configure App Groups before running on a physical device.

### Step 1: Clone and Open

1. Clone this repository to your local directory.
2. Open `batagor.xcodeproj` using Xcode.

### Step 2: Set Your Own Bundle Identifier

The team-default bundle identifier (`com.tudemaha.lawar`) and its App Group are tied
to one signing team, so you need your own before the App Group will work under your
account:

1. Run `./scripts/local-bundle-id.sh set <your-suffix>` from the repo root — this
   rewrites the bundle identifier and App Group for both targets in one shot (see
   `CONTRIBUTING.md` for details).
2. Run `git config core.hooksPath .githooks` once so future `git pull`s
   automatically keep your identifier instead of reverting to the team default.

### Step 3: Configure Signing & Capabilities (For Physical Devices)

1. Select the root **batagor** project in the Xcode Project Navigator.
2. Under **Targets**, select the **batagor** target.
3. Navigate to the **Signing & Capabilities** tab.
4. Select your **Team** to resolve provisioning profile errors.
5. In the **App Groups** section, add/select the group the script wrote in Step 2
   (`group.com.tudemaha.<your-suffix>`).
6. Repeat the same signing configuration steps for the **widget** target.

### Step 4: Run the Application

1. Select a simulator or an iOS 17+ physical device from the Run Destinations.
2. Build and run (`Cmd + R`) the **batagor** scheme.

---

## 📁 Project Structure

```
batagor/
├── batagor/                     # Main Application Folder
│   ├── AppDelegate.swift        # App-wide lifecycle delegation
│   ├── batagorApp.swift         # SwiftUI App Entrance Point
│   ├── Core/                    # Core Architecture Components
│   │   ├── Helpers/             # Stateless utility operations & formatting
│   │   └── Services/            # Device wrappers and business logic services
│   ├── Extensions/              # Foundation and SwiftUI type extensions
│   ├── Models/                  # SwiftData entities & plain data models
│   ├── ViewModels/              # MVVM ViewModel layer for views
│   ├── Views/                   # SwiftUI View Components
│   │   ├── Camera/              # Camera capturing UI
│   │   ├── Detail/              # Detailed item view
│   │   ├── Gallery/             # Gallery library grid
│   │   └── Shared/              # Shared/Reusable UI components
│   └── Resources/               # Assets, Fonts, & Plists
└── widget/                      # Home Screen Widget Extension
```

### What goes into each directory:

- `Core/Helpers/`: Pure utility structures containing static methods for transformations (e.g., formatting dates, configuring typography).
- `Core/Services/`: Stateless or stateful managers that perform operations. These interface with hardware/system APIs (Camera, Location, Haptics) or manage database contexts.
- `Extensions/`: Custom functionality added to standard framework types (e.g., helper properties on `Color` or `Font`).
- `Models/`: SwiftData `@Model` classes representing persistent tables and data representations.
- `ViewModels/`: Swift classes conforming to `ObservableObject` holding the UI state and binding view events to services.
- `Views/`: SwiftUI components and views separated by app module (e.g., Gallery, Camera, Detail).
- `widget/`: Code specifically related to the App Widget Extension, providing widgets to display temporary media count/timer data.

---

## ✏️ Naming Conventions

This project strictly adheres to clean, predictable SwiftUI and MVVM naming standards.

### 1. Helpers (`Core/Helpers/`)

- **Suffix**: `Formatter` or `Manager` (e.g., `TimeFormatter`, `FontManager`).
- **Design**: Structs with static functions. They should be stateless and lack shared singleton instances.

### 2. Services (`Core/Services/`)

Services are classified into two sub-categories:

- **Managers (`*Manager`)**: Stateful classes wrapping system/hardware APIs or app-wide UI/Navigation states (e.g., `LocationManager`, `CameraManager`, `NavigationManager`, `HapticManager`).
  - _Rules_: Conforms to `ObservableObject` to publish state updates using `@Published` properties, accessed via `static let shared` singleton.
- **Services (`*Service`)**: Domain/business logic wrappers performing transactional or data operations (e.g., `DeletionService`, `ModelContainerService`).
  - _Rules_: Standard classes accessed via `static let shared` singletons. Do not conform to `ObservableObject` unless UI binding is explicitly needed.

### 3. ViewModels (`ViewModels/`)

- **Suffix**: `ViewModel` (e.g., `CameraViewModel`).
- **Design**: Conforms to `ObservableObject` and `@MainActor` to bind async/background updates cleanly back to the main UI thread.

### 4. Views (`Views/`)

- **Suffix**: `View` (e.g., `GalleryView`, `GalleryItemView`), except for the primary container entry points if concise (e.g., `Camera`).
- **Design**: Structs conforming to `View`, using `@EnvironmentObject` or `@StateObject` to consume Managers or ViewModels.
