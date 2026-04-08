//
//  MapView.swift
//  ARHUD
//
//  2D top-down map view with POI markers
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @ObservedObject var hudSettings: HUDSettings
    @ObservedObject var locationManager: LocationDataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Filter POIs based on settings
    private var filteredPOIs: [POIData] {
        locationManager.nearbyPOIs.filter { poi in
            switch poi.category {
            case .landmark:
                return hudSettings.showLandmarks
            case .restaurant:
                return hudSettings.showRestaurants
            case .park:
                return hudSettings.showParks
            case .transit:
                return hudSettings.showTransit
            case .other:
                return true
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: filteredPOIs) { poi in
                MapAnnotation(coordinate: poi.coordinate) {
                    POIMapMarker(poi: poi, hudSettings: hudSettings)
                }
            }
            .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                            Text("AR View")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(hudSettings.hudColor, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // Recenter button
                    Button(action: centerOnUser) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(hudSettings.hudColor, lineWidth: 1)
                            )
                    }
                }
                .padding()
                
                Spacer()
                
                // Stats at bottom
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        StatBadge(icon: "building.2", count: filteredPOIs.filter { $0.category == .landmark }.count, label: "Landmarks", color: .yellow)
                        StatBadge(icon: "fork.knife", count: filteredPOIs.filter { $0.category == .restaurant }.count, label: "Food", color: .orange)
                        StatBadge(icon: "tree", count: filteredPOIs.filter { $0.category == .park }.count, label: "Parks", color: .green)
                        StatBadge(icon: "tram", count: filteredPOIs.filter { $0.category == .transit }.count, label: "Transit", color: .blue)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                    )
                    
                    if let location = locationManager.location {
                        HStack(spacing: 12) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(hudSettings.hudColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let street = locationManager.currentStreet {
                                    Text(street)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                Text(String(format: "%.4f°, %.4f°", location.coordinate.latitude, location.coordinate.longitude))
                                    .font(.system(size: 11, design: .monospaced))
                                    .opacity(0.7)
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
        }
        .onAppear {
            centerOnUser()
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                // Smoothly follow user location
                withAnimation(.easeInOut(duration: 0.3)) {
                    region.center = location.coordinate
                }
            }
        }
    }
    
    private func centerOnUser() {
        guard let location = locationManager.location else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

// MARK: - POI Map Marker

struct POIMapMarker: View {
    let poi: POIData
    let hudSettings: HUDSettings
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                // Glow
                Circle()
                    .fill(Color(poi.category.color))
                    .frame(width: 40, height: 40)
                    .blur(radius: 10)
                    .opacity(0.6)
                
                // Background
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                
                // Icon
                Image(systemName: poi.category.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(poi.category.color))
            }
            .overlay(
                Circle()
                    .stroke(Color(poi.category.color), lineWidth: 2.5)
                    .frame(width: 32, height: 32)
            )
            .shadow(color: .black.opacity(0.3), radius: 4)
            
            // Name popup
            if showDetails {
                VStack(spacing: 4) {
                    Text(poi.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(formatDistance(poi.distance))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(poi.category.color))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.9))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(poi.category.color), lineWidth: 1)
                )
                .offset(y: -45)
                .transition(.opacity)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showDetails.toggle()
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

// MARK: - Map Stat Badge

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 70)
    }
}

// MARK: - Preview

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            hudSettings: HUDSettings(),
            locationManager: LocationDataManager()
        )
    }
}
