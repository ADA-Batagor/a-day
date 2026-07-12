//
//  Toast.swift
//  batagor
//
//  Created by Gede Pramananda Kusuma Wisesa on 11/11/25.
//

import SwiftUI

struct Toast: View {
    let message: String
    let icon: String
    
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .fontWeight(.semibold)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.lightBase)
            
            Text(message)
                .font(.spaceGroteskRegular(size: 17))
                .foregroundStyle(Color.lightBase)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.darkerBlue90.opacity(0.9))
        .cornerRadius(20)
        .padding(.horizontal)
        .onTapGesture {
            dismissToast()
        }
    }
    
    private func dismissToast() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let icon: String
    let duration: TimeInterval
    
    @State private var workItem: DispatchWorkItem?
    @State private var animationId: UUID = UUID()
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            VStack {
                Spacer()
                
                if isShowing {
                    Toast(message: message, icon: icon, isShowing: $isShowing)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id(animationId)
                        .onAppear {
                            scheduleAutoDismiss()
                        }
                        .onChange(of: isShowing) { oldValue, newValue in
                            if newValue && oldValue {
                                animationId = UUID()
                                scheduleAutoDismiss()
                            }
                        }
                }
            }
            .padding(.bottom, 80)
        }
        
    }
    
    private func scheduleAutoDismiss() {
        workItem?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isShowing = false
            }
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

extension View {
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        icon: String = "exclamationmark.triangle",
        duration: TimeInterval = 3.0
    ) -> some View {
        self.modifier(ToastModifier(
            isShowing: isShowing,
            message: message,
            icon: icon,
            duration: duration
        ))
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Content")
    }
    .toast(
        isShowing: .constant(true),
        message: "Please delete media first to open continue capturing.",
        icon: "exclamationmark.triangle"
    )
}
