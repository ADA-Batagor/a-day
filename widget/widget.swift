//
//  widget.swift
//  widget
//
//  Created by Gede Pramananda Kusuma Wisesa on 28/10/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GalleryEntry {
        GalleryEntry(date: Date(), media: [], count: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (GalleryEntry) -> Void) {
        let entry = GalleryEntry(date: Date(), media: [], count: 0)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<GalleryEntry>) -> Void) {
        Task {
            let currentDate = Date()
            let media = await fetchRecentMedia(limit: 4)
            let count = await fetchCountMedia()
            let entry = GalleryEntry(date: currentDate, media: media, count: count)
            print(entry)
            
            let nextUpdate: Date
            if media.isEmpty {
                nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
            } else {
                nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
            }
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
        
    }
    
    @MainActor private func fetchRecentMedia(limit: Int) -> [Storage] {
        let modelContext = ModelContainerService.shared.mainContext
        
        let descriptor = FetchDescriptor<Storage>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        
        guard let allStorages = try? modelContext.fetch(descriptor) else {
            print("fetchRecentMedia: failed to fetch all storages")
            return []
        }
        
        let validMedia = allStorages.filter{!$0.isExpired}.prefix(limit)
        return validMedia.compactMap { storage in
            guard StorageManager.shared.loadUIImage(fileURL: storage.thumbnailPath) != nil else {
                print("fetchRecentMedia: thumbnail not found \(storage.thumbnailPath)")
                return nil
            }
            return storage
        }
    }
    
    @MainActor private func fetchCountMedia() -> Int {
        let modelContext = ModelContainerService.shared.mainContext
        
        let descriptor = FetchDescriptor<Storage>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let allStorages = try? modelContext.fetch(descriptor) else {
            print("fetchCountMedia: failed to fetch all storages")
            return 0
        }
        let validMedia = allStorages.filter{!$0.isExpired}
        return validMedia.count
    }

}

// MARK: - Helper Functions
  func loadThumbnailForWidget(fileURL: URL, maxDimension: CGFloat = 400) -> UIImage? {
      guard let fullImage = StorageManager.shared.loadUIImage(fileURL: fileURL) else {
          return nil
      }

      return fullImage.resizedForWidget(maxDimension: maxDimension)
  }

struct GalleryEntry: TimelineEntry {
    let date: Date
    let media: [Storage]
    let count: Int
}

struct widgetEntryView : View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            switch family {
            case .systemSmall:
                SmallWidgetView(media: entry.media)
            case .systemMedium:
                MediumWidgetView(media: entry.media, count: entry.count)
    //        case .systemLarge:
    //            LargeWidgetView(media: entry.media)
            default:
                SmallWidgetView(media: entry.media)
            }
        }
    }
}

// MARK: - Small Widget (1 photo)
struct SmallWidgetView: View {
    let media: [Storage]

    var body: some View {
        ZStack(alignment: .center) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color.init(hex: "E1EAFD"), location: 0.0),
                    Gradient.Stop(color: Color.init(hex: "FAF4E6"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            if let media = media.first {
                let mediaImage = loadThumbnailForWidget(fileURL: media.thumbnailPath)
                if let mediaImage = mediaImage {
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.darkBase)
                            
                            Text(TimeFormatter.formatTimeRemaining(media.timeRemaining))
                                .font(.spaceGroteskSemiBold(size: 17))
                                .foregroundColor(Color.darkBase)
                            
                            Spacer()
                            
                            ProgressView(value: Double(media.timeRemaining), total: 86400)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.darkerBlue90))
                                .background(Color.darkerBlue90.opacity(0.4))
                                .cornerRadius(20)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .frame(height: 6)
                                
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        
                        Link(destination: createMediaDeepLink(for: media)) {
                            ZStack(alignment: .bottom) {
                                GeometryReader { geometry in
                                    Image(uiImage: mediaImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .cornerRadius(20)
                                }
                                
                                VStack {
                                    if let location = media.locationName {
                                        Text(location)
                                            .font(.spaceGroteskRegular(size: 10))
                                            .foregroundStyle(Color.lightBase)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.darkerBlue70.opacity(0.8))
                                            )
                                    } else {
                                        Text("Location Unknown")
                                            .font(.spaceGroteskRegular(size: 10))
                                            .foregroundColor(Color.lightBase)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.darkerBlue70.opacity(0.8))
                                            )
                                    }
                                }
                                .padding(.bottom, 8)
                                
                            }
                            .padding(8)
                        }
                    }
                }
            } else {
                Link(destination: URL(string: "batagor://camera")!) {
                    EmptyWidgetView()
                }
                
            }
        }
    }
}

// MARK: - Medium Widget (2 photos)
struct MediumWidgetView: View {
    let media: [Storage]
    let count: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.init(hex: "E1EAFD"), location: 0.0),
                        Gradient.Stop(color: Color.init(hex: "FAF4E6"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("From Today")
                            .font(.spaceGroteskSemiBold(size: 17))
                            .foregroundStyle(Color.darkBase)
                        
                        Spacer()
                        
                        CircularProgress(
                            current: count,
                            total: 24,
                            isShowCount: true,
                            foregroundColor: Color.darkBase,
                            font: .spaceGroteskSemiBold(size: 17)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    if !media.isEmpty {
                        HStack(spacing: 8) {
                            Link(destination: URL(string: "batagor://camera")!) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue70)
                                    
                                    VStack(spacing: 8) {
                                        ZStack {
                                            VStack {
                                                HStack {
                                                    Image("TopLeft")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                    
                                                    Spacer()
                                                    
                                                    Image("TopRight")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                }
                                                
                                                Spacer()
                                                
                                                HStack {
                                                    Image("BottomLeft")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                    
                                                    Spacer()
                                                    
                                                    Image("BottomRight")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                            .padding(8)
                                            
                                            Image(systemName: "camera")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color.lightBase)
                                        }
                                    }
                                }
                                .frame(width: (geometry.size.width - 56) / 4, height: 100)
                            }
                            ForEach(media.prefix(3)) { mediaItem in
                                Link(destination: createMediaDeepLink(for: mediaItem)) {
                                    let mediaImage = loadThumbnailForWidget(fileURL: mediaItem.thumbnailPath)
                                    if let mediaImage = mediaImage {
                                        ZStack(alignment: .bottomLeading) {
                                            Image(uiImage: mediaImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: (geometry.size.width - 56) / 4, height: 100)
                                                .clipped()
                                                .cornerRadius(12)
                                            
                                            ZStack(alignment: .bottomLeading) {
                                                LinearGradient(
                                                    stops: [
                                                        Gradient.Stop(color: .black.opacity(0.7), location: 0.0),
                                                        Gradient.Stop(color: .black.opacity(0.4), location: 0.15),
                                                        Gradient.Stop(color: .black.opacity(0.15), location: 0.2),
                                                        Gradient.Stop(color: .clear, location: 0.3)
                                                    ],
                                                    startPoint: .bottomLeading,
                                                    endPoint: .topTrailing
                                                )
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "clock")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(Color.lightBase)
                                                    
                                                    Text(TimeFormatter.formatTimeRemaining(mediaItem.timeRemaining))
                                                        .font(.spaceGroteskSemiBold(size: 11))
                                                        .foregroundColor(Color.lightBase)
                                                }
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 4)
                                            }
                                            .frame(width: (geometry.size.width - 56) / 4, height: 100)
                                            .clipShape(
                                                UnevenRoundedRectangle(
                                                    cornerRadii: .init(
                                                        topLeading: 0,
                                                        bottomLeading: 12,
                                                        bottomTrailing: 12,
                                                        topTrailing: 12
                                                    )
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    } else {
                        HStack(spacing: 8) {
                            Link(destination: URL(string: "batagor://camera")!) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue70)
                                    
                                    VStack(spacing: 8) {
                                        ZStack {
                                            VStack {
                                                HStack {
                                                    Image("TopLeft")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                    
                                                    Spacer()
                                                    
                                                    Image("TopRight")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                }
                                                
                                                Spacer()
                                                
                                                HStack {
                                                    Image("BottomLeft")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                    
                                                    Spacer()
                                                    
                                                    Image("BottomRight")
                                                        .resizable()
                                                        .renderingMode(.template)
                                                        .foregroundColor(Color.lightBase)
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                            .padding(8)
                                            
                                            Image(systemName: "camera")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color.lightBase)
                                        }
                                    }
                                }
                                .frame(width: (geometry.size.width - 56) / 4, height: 100)
                            }
                            ForEach(0..<3) { _ in
                                ZStack(alignment: .bottomLeading) {
                                    ZStack(alignment: .bottomLeading) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.gray)
                                    }
                                    .frame(width: (geometry.size.width - 56) / 4, height: 100)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            cornerRadii: .init(
                                                topLeading: 0,
                                                bottomLeading: 12,
                                                bottomTrailing: 12,
                                                topTrailing: 12
                                            )
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.darkerBlue70, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                    }
                }
            }
        }
        
    }
}

// MARK: - Large Widget (2x2 grid photos)
struct LargeWidgetView: View {
    let media: [Storage]

    var body: some View {
        if media.isEmpty {
            EmptyWidgetView()
        } else {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    ForEach(media.prefix(2)) { media in
                        let mediaImage = loadThumbnailForWidget(fileURL: media.thumbnailPath)
                        if let mediaImage = mediaImage {
                            Image(uiImage: mediaImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                        }
                    }
                }

                if media.count > 2 {
                    HStack(spacing: 2) {
                        ForEach(media.prefix(2)) { media in
                            let mediaImage = loadThumbnailForWidget(fileURL: media.thumbnailPath)
                            if let mediaImage = mediaImage {
                                Image(uiImage: mediaImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Empty State
struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 30))
                .foregroundStyle(Color.darkBase)
            
            VStack(alignment: .center, spacing: 4) {
                Text("A clear day.")
                    .font(.spaceGroteskBold(size: 17))
                    .foregroundStyle(Color.darkBase)
                
                Text("Let’s get your first snap. It’ll be here for 24 hours.")
                    .font(.spaceGroteskRegular(size: 10))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.darkBase)
            }
        }
        .padding()
    }
}


// MARK: - UIImage Widget Extension
extension UIImage {
    func resizedForWidget(maxDimension: CGFloat) -> UIImage {
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }
        
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}


struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recents")
        .description("View your most recent captured media")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private func createMediaDeepLink(for media: Storage) -> URL {
    return URL(string: "batagor://media/\(media.id.uuidString)")!
}



// MARK: - Preview Sample Data
extension GalleryEntry {
    static var sampleMedia: [Storage] {
        (1...4).map { index in
            Storage(
                mainPath: URL(fileURLWithPath: "/tmp/sample\(index).jpg"),
                thumbnailPath: URL(fileURLWithPath:
                                    "/tmp/sample\(index)_thumb.jpg")
            )
        }
    }
    
    static var sampleEntry: GalleryEntry {
        GalleryEntry(date: .now, media: sampleMedia, count: 12)
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    widget()
} timeline: {
//    GalleryEntry.sampleEntry
    GalleryEntry(date: Date(), media: [], count: 0)
}

#Preview(as: .systemMedium) {
    widget()
} timeline: {
//    GalleryEntry.sampleEntry
    GalleryEntry(date: Date(), media: [], count: 0)
}

#Preview(as: .systemLarge) {
    widget()
} timeline: {
//    GalleryEntry.sampleEntry
    GalleryEntry(date: Date(), media: [], count: 0)
}
