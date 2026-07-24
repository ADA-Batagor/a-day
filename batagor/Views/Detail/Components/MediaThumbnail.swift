//
//  MapThumbnail.swift
//  batagor
//
//  Created by Tude Maha on 24/11/2025.
//

import SwiftUI
import MapKit

struct MapThumbnail: View {
    var storage: Storage
    @State private var position: MapCameraPosition
    
    init(storage: Storage) {
        self.storage = storage
        
        _position = State(initialValue:
                .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: storage.latitude ?? 0.0, longitude: storage.longitude ?? 0.0),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
        )
    }
    
    var body: some View {
        Map(position: $position, interactionModes: []) {
            Marker("", coordinate: CLLocationCoordinate2D(latitude: storage.latitude ?? 0.0, longitude: storage.longitude ?? 0.0))
        }
    }
}

//#Preview {
//    MapThumbnail()
//}
