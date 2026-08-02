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
            .background(Color.lightBase)
            .cornerRadius(14)
            .padding(.horizontal, 8)
            
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
            .background(Color.lightBase)
            .cornerRadius(14)
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .padding(.bottom, 8)
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
            .sheet(isPresented: isPresented) {
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
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color.clear)
            }
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
