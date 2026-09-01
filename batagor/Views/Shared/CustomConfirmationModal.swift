//
//  CustomConfirmationModal.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 17/11/25.
//

import SwiftUI

struct CustomConfirmationDialog: View {
    var title: String
    var message: String
    var actionTitle: String
    var cancelTitle: String = "Cancel"
    var actionColor: Color = .redBase
    var onAction: () -> Void
    var onCancel: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if #available(iOS 26.0, *) {
                    messageCard
                        .glassEffect(.regular.tint(Color.lightBase), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    messageCard
                        .background(Color.lightBase)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 8)

            Group {
                if #available(iOS 26.0, *) {
                    cancelButton
                        .glassEffect(.regular.tint(Color.lightBase), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    cancelButton
                        .background(Color.lightBase)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .padding(.bottom, 8)
    }

    private var messageCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.spaceGroteskSemiBold(size: 13))
                    .foregroundStyle(Color.darkBase)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text(message)
                    .font(.spaceGroteskRegular(size: 13))
                    .foregroundStyle(Color.darkBase)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 14)
            .padding(.horizontal, 16)

            Divider()
                .background(Color.darkBase.opacity(0.2))

            Button {
                onAction()
                isPresented = false
            } label: {
                Text(actionTitle)
                    .font(.spaceGroteskSemiBold(size: 17))
                    .foregroundStyle(actionColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
            }
        }
    }

    private var cancelButton: some View {
        Button {
            onCancel()
            isPresented = false
        } label: {
            Text(cancelTitle)
                .font(.spaceGroteskSemiBold(size: 17))
                .foregroundStyle(Color.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }
}

struct CustomConfirmationDialogModifier: ViewModifier {
    var title: String
    var message: String
    var actionTitle: String
    var cancelTitle: String
    var actionColor: Color
    var isPresented: Binding<Bool>
    var onAction: () -> Void
    var onCancel: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                // Presented as a plain overlay (matching `CustomAlert`'s pattern) rather
                // than `.sheet` — on iOS 26, `.sheet` wraps content in the system's own
                // Liquid Glass chrome, which at this dialog's small custom height
                // produced a broken-looking smeared/discolored backdrop. Owning the
                // presentation ourselves lets the two cards below apply their own
                // clean, explicit glass instead.
                if isPresented.wrappedValue {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                onCancel()
                                isPresented.wrappedValue = false
                            }

                        VStack {
                            Spacer()
                            CustomConfirmationDialog(
                                title: title,
                                message: message,
                                actionTitle: actionTitle,
                                cancelTitle: cancelTitle,
                                actionColor: actionColor,
                                onAction: onAction,
                                onCancel: onCancel,
                                isPresented: isPresented
                            )
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
}

extension View {
    func customConfirmationDialog(
        _ title: String,
        isPresented: Binding<Bool>,
        actionTitle: String,
        actionColor: Color = .redBase,
        cancelTitle: String = "Cancel",
        action: @escaping () -> Void,
        cancel: @escaping () -> Void = {},
        message: String
    ) -> some View {
        self.modifier(
            CustomConfirmationDialogModifier(
                title: title,
                message: message,
                actionTitle: actionTitle,
                cancelTitle: cancelTitle,
                actionColor: actionColor,
                isPresented: isPresented,
                onAction: action,
                onCancel: cancel
            )
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true

        var body: some View {
            Color.darkBase.opacity(0.3)
                .ignoresSafeArea()
                .customConfirmationDialog(
                    "Don't need this snap anymore?",
                    isPresented: $isPresented,
                    actionTitle: "Delete",
                    actionColor: .redBase,
                    action: { print("Delete") },
                    cancel: { print("Cancel") },
                    message: "This will delete it for good. This action can't be undone."
                )
        }
    }

    return PreviewWrapper()
}
