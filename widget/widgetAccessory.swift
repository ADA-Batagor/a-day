//
//  widgetAccessory.swift
//  widget
//
//  Created by Gede Pramananda Kusuma Wisesa on 03/09/26.
//

import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

private let snapLimit = 24

// MARK: - Configuration

enum AccessoryMode: String, AppEnum {
    case camera
    case timeLeft
    case count

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Show"

    static var caseDisplayRepresentations: [AccessoryMode: DisplayRepresentation] = [
        .camera: DisplayRepresentation(
            title: "Open Camera",
            image: .init(systemName: "camera.viewfinder")
        ),
        .timeLeft: DisplayRepresentation(
            title: "Time Left",
            image: .init(systemName: "clock")
        ),
        .count: DisplayRepresentation(
            title: "Today's Count",
            image: .init(systemName: "circle.dashed")
        )
    ]
}

struct AccessoryConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Lock Screen Widget"
    static var description = IntentDescription("Choose what this widget shows.")

    @Parameter(title: "Show", default: .camera)
    var mode: AccessoryMode
}

// MARK: - Timeline

struct AccessoryEntry: TimelineEntry {
    let date: Date
    let mode: AccessoryMode
    let latestExpiry: Date?
    let count: Int
}

struct AccessoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> AccessoryEntry {
        AccessoryEntry(date: Date(), mode: .camera, latestExpiry: nil, count: 0)
    }

    func snapshot(for configuration: AccessoryConfigurationIntent, in context: Context) async -> AccessoryEntry {
        let state = await fetchState()
        return AccessoryEntry(
            date: Date(),
            mode: configuration.mode,
            latestExpiry: state.latestExpiry,
            count: state.count
        )
    }

    /// Countdown and gauge views update themselves on screen, so the reload policy only
    /// has to cover the moments the *data* changes: a snap expiring. Everything else is
    /// already pushed by the app's `WidgetCenter.shared.reloadAllTimelines()` calls.
    /// This keeps the Lock Screen widget off the refresh budget the Home Screen widget needs.
    func timeline(for configuration: AccessoryConfigurationIntent, in context: Context) async -> Timeline<AccessoryEntry> {
        let state = await fetchState()
        let entry = AccessoryEntry(
            date: Date(),
            mode: configuration.mode,
            latestExpiry: state.latestExpiry,
            count: state.count
        )

        let policy: TimelineReloadPolicy
        switch configuration.mode {
        case .camera:
            policy = .never
        case .timeLeft:
            // Only the newest snap is shown, so nothing changes until it expires.
            policy = state.latestExpiry.map { .after($0) } ?? .never
        case .count:
            // The count drops when the *oldest* surviving snap expires.
            policy = state.earliestExpiry.map { .after($0) } ?? .never
        }

        return Timeline(entries: [entry], policy: policy)
    }

    @MainActor
    private func fetchState() -> (latestExpiry: Date?, earliestExpiry: Date?, count: Int) {
        let modelContext = ModelContainerService.shared.mainContext

        let descriptor = FetchDescriptor<Storage>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let allStorages = try? modelContext.fetch(descriptor) else {
            print("fetchState: failed to fetch all storages")
            return (nil, nil, 0)
        }

        let expiries = allStorages.filter { !$0.isExpired }.map(\.expiredAt)
        return (expiries.max(), expiries.min(), expiries.count)
    }
}

// MARK: - Entry View

struct widgetAccessoryEntryView: View {
    var entry: AccessoryEntry

    var body: some View {
        switch entry.mode {
        case .camera:
            CameraAccessoryView()
                .widgetURL(URL(string: "batagor://camera")!)
        case .timeLeft:
            TimeLeftAccessoryView(entry: entry)
                .widgetURL(URL(string: "batagor://gallery")!)
        case .count:
            CountAccessoryView(count: entry.count)
                .widgetURL(URL(string: "batagor://gallery")!)
        }
    }
}

// MARK: - Open Camera
struct CameraAccessoryView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Capture Snaps", systemImage: "camera.viewfinder")

        case .accessoryRectangular:
            Button(intent: OpenCameraIntent()) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .widgetAccentable()

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Capture Snaps")
                            .font(.spaceGroteskSemiBold(size: 15))
                            .widgetAccentable()

                        Text("Lasts 24 hours")
                            .font(.spaceGroteskRegular(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

        default:
            Button(intent: OpenCameraIntent()) {
                ZStack {
                    AccessoryWidgetBackground()

                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .widgetAccentable()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Time Left
struct TimeLeftAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: AccessoryEntry

    // nil once the newest snap has expired — the timeline reload that clears it
    // may not have landed yet, so the views need an empty state either way.
    private var range: ClosedRange<Date>? {
        guard let expiry = entry.latestExpiry, expiry > entry.date else { return nil }
        return entry.date...expiry
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let range {
                Text(timerInterval: range, countsDown: true)
            } else {
                Text("No snaps yet")
            }

        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 22, weight: .medium))
                    .widgetAccentable()

                VStack(alignment: .leading, spacing: 1) {
                    if let range {
                        Text(timerInterval: range, countsDown: true)
                            .font(.spaceGroteskSemiBold(size: 15))
                            .widgetAccentable()

                        Text("until it's gone")
                            .font(.spaceGroteskRegular(size: 12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No snaps yet")
                            .font(.spaceGroteskSemiBold(size: 15))
                            .widgetAccentable()

                        Text("Tap to capture")
                            .font(.spaceGroteskRegular(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

        default:
            ZStack {
                AccessoryWidgetBackground()

                if let range {
                    ProgressView(timerInterval: range, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .progressViewStyle(.circular)
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 22, weight: .medium))
                        .widgetAccentable()
                }
            }
        }
    }
}

// MARK: - Today's Count
struct CountAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let count: Int

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(count)/\(snapLimit) snaps")

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text("\(count) of \(snapLimit) snaps")
                    .font(.spaceGroteskSemiBold(size: 15))
                    .widgetAccentable()

                Gauge(value: Double(count), in: 0...Double(snapLimit)) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }

        default:
            ZStack {
                AccessoryWidgetBackground()

                Gauge(value: Double(count), in: 0...Double(snapLimit)) {
                    Image(systemName: "camera.fill")
                } currentValueLabel: {
                    Text("\(count)")
                        .font(.spaceGroteskSemiBold(size: 15))
                }
                .gaugeStyle(.accessoryCircularCapacity)
            }
        }
    }
}

// MARK: - Widget

struct widgetAccessory: Widget {
    let kind: String = "widgetAccessory"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AccessoryConfigurationIntent.self,
            provider: AccessoryProvider()
        ) { entry in
            widgetAccessoryEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("A Day")
        .description("Open the camera, or keep an eye on today's snaps.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Previews

#Preview(as: .accessoryCircular) {
    widgetAccessory()
} timeline: {
    AccessoryEntry(date: Date(), mode: .camera, latestExpiry: nil, count: 0)
    AccessoryEntry(date: Date(), mode: .timeLeft, latestExpiry: Date().addingTimeInterval(3600 * 21), count: 12)
    AccessoryEntry(date: Date(), mode: .count, latestExpiry: nil, count: 12)
}

#Preview(as: .accessoryRectangular) {
    widgetAccessory()
} timeline: {
    AccessoryEntry(date: Date(), mode: .camera, latestExpiry: nil, count: 0)
    AccessoryEntry(date: Date(), mode: .timeLeft, latestExpiry: Date().addingTimeInterval(3600 * 21), count: 12)
    AccessoryEntry(date: Date(), mode: .count, latestExpiry: nil, count: 12)
}

#Preview(as: .accessoryInline) {
    widgetAccessory()
} timeline: {
    AccessoryEntry(date: Date(), mode: .timeLeft, latestExpiry: Date().addingTimeInterval(3600 * 21), count: 12)
}
