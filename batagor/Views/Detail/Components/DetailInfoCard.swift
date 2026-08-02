//
//  DetailInfoCard.swift
//  batagor
//
//  Created by Tude Maha on 26/07/2026.
//

import SwiftUI

struct DetailInfoCard: View {
    var storage: Storage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            infoRow(
                icon: "camera.fill",
                tint: .darkerBlueBase,
                label: "Captured",
                value: storage.createdAt.formatted(date: .abbreviated, time: .shortened)
            )

            infoRow(
                icon: "hourglass",
                tint: .yellow60,
                label: "Disappears",
                value: storage.expiredAt.formatted(date: .abbreviated, time: .shortened)
            )

            if let location = storage.locationName,
               let city = storage.locationCity {
                infoRow(
                    icon: "mappin.and.ellipse",
                    tint: .redBase,
                    label: "Location",
                    value: "\(location), \(city)"
                )

                MapThumbnail(storage: storage)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.dark30.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.light20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.dark30.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func infoRow(icon: String, tint: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.spaceGroteskMedium(size: 12))
                    .foregroundStyle(Color.dark40)
                Text(value)
                    .font(.spaceGroteskSemiBold(size: 15))
                    .foregroundStyle(Color.darkBase)
            }

            Spacer()
        }
    }
}

#Preview {
    DetailInfoCard(storage: Storage(
        mainPath: URL(string: "https://example.com")!,
        thumbnailPath: URL(string: "https://example.com")!
    ))
    .padding()
}
