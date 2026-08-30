//
//  SettingsView.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 18/11/25.
//

import SwiftUI
import Photos

struct SettingsView: View {
    private static let feedbackEmail = "btgr.dev@gmail.com"
    private static let feedbackSubject = "A Day — Feedback"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var locationManager = LocationManager()

    @State private var photosStatus: PermissionState = .notSet
    @State private var locationStatus: PermissionState = .notSet

    @State private var showMailUnavailableAlert = false
    @State private var showContactConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.spaceGroteskBold(size: 34))
                    .foregroundStyle(Color.darkerBlueBase)

                VStack(alignment: .leading, spacing: 8) {
                    SettingsRow(
                        title: "Photos",
                        statusText: photosStatus.rawValue,
                        showDrillIn: photosStatus != .on
                    ) {
                        handlePermissionTap(.photos, currentStatus: photosStatus)
                    }
                    Text("Used to save your photos and videos before they disappear.")
                        .font(.spaceGroteskBold(size: 13))
                        .foregroundStyle(Color.dark30)
                        .padding(.leading, 18)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SettingsRow(
                        title: "Location",
                        statusText: locationStatus.rawValue,
                        showDrillIn: locationStatus != .on
                    ) {
                        handlePermissionTap(.location, currentStatus: locationStatus)
                    }
                    Text("Used to tag where your photo was taken. Optional.")
                        .font(.spaceGroteskBold(size: 13))
                        .foregroundStyle(Color.dark30)
                        .padding(.leading, 18)
                }

                VStack(alignment: .leading, spacing: 8) {
                    // Dialog is attached to the row rather than the ScrollView so
                    // iOS 26 anchors it to the tapped field; on the root view it
                    // emerges from the top of the page instead.
                    SettingsRow(title: "Contact us") {
                        showContactConfirmation = true
                    }
                    .confirmationDialog(
                        "Send Feedback",
                        isPresented: $showContactConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Open Mail") {
                            openMailContact()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will open Mail to send us a message.")
                    }
                    Text("Got a bug or an idea? We'd love to hear from you.")
                        .font(.spaceGroteskBold(size: 13))
                        .foregroundStyle(Color.dark30)
                        .padding(.leading, 18)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color.lightBase)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        CircleButton(icon: "chevron.backward")
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        CircleButton(icon: "chevron.backward")
                    }
                }
            }
        }
        .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
            Button("Copy Email") {
                UIPasteboard.general.string = Self.feedbackEmail
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can reach us at \(Self.feedbackEmail)")
        }
        .onAppear {
            refreshPermissionStatuses()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshPermissionStatuses()
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            refreshPermissionStatuses()
        }
    }

    private func refreshPermissionStatuses() {
        photosStatus = PermissionStatusService.status(for: .photos)
        locationStatus = PermissionStatusService.status(for: .location)
    }

    /// `notSet` triggers the native OS permission prompt in-place; `off` opens
    /// iOS Settings, since re-prompting isn't possible once denied. `on` has no
    /// further action (row hides its chevron and does nothing on tap).
    private func handlePermissionTap(_ kind: PermissionKind, currentStatus: PermissionState) {
        switch currentStatus {
        case .notSet:
            requestPermission(kind)
        case .off:
            openAppSettings()
        case .on:
            break
        }
    }

    private func requestPermission(_ kind: PermissionKind) {
        switch kind {
        case .photos:
            Task {
                _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                await MainActor.run { refreshPermissionStatuses() }
            }
        case .location:
            locationManager.requestPermission()
        case .camera, .microphone:
            break
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func openMailContact() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.feedbackEmail
        components.queryItems = [URLQueryItem(name: "subject", value: Self.feedbackSubject)]

        guard let url = components.url, UIApplication.shared.canOpenURL(url) else {
            showMailUnavailableAlert = true
            return
        }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
