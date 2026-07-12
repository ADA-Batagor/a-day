//
//  TimerManager.swift
//  batagor
//
//  Created by Tude Maha on 28/10/2025.
//

import Foundation
import Combine

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
