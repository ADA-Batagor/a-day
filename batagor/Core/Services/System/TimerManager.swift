//
//  TimerManager.swift
//  batagor
//
//  Created by Tude Maha on 28/10/2025.
//

import Foundation
import Combine

/// Publishes a shared `Date` that ticks every second, so any view showing a
/// countdown (e.g. remaining time before a `Storage` item expires) can observe one
/// clock instead of each running its own `Timer`.
class TimerManager: ObservableObject {
    static let shared = TimerManager()

    @Published var currentTime = Date()
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] time in
                self?.currentTime = time
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
