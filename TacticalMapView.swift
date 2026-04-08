//
//  TacticalMapView.swift
//  ARHUD
//
//  2D top-down tactical map with POI markers
//

import SwiftUI
import MapKit

struct TacticalMapView: View {
    @ObservedObject var hudSettings: HUDSettings
    @ObservedObject var locationManager: LocationDataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var followUser = true
    
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
            .edgesIgnoringSafeArea(.all)
            
            // HUD-style overlay
            VStack {
                // Top bar
                HStack {
                    // Back to AR button
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                            Text("AR VIEW")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(hudSettings.hudColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hudSettings.hudColor.opacity(0.6), lineWidth: 2)
                        )
                    }
                    
                    Spacer()
                    
                    // Map title
                    VStack(spacing: 2) {
                        Text("TACTICAL MAP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(hudSettings.hudColor)
                        
                        if let heading = locationManager.heading {
                            Text(String(format: "HDG: %.0f°", heading))
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundColor(hudSettings.hudColor.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(hudSettings.hudColor.opacity(0.6), lineWidth: 2)
                    )
                    
                    Spacer()
                    
                    // Tracking mode toggle
                    Button(action: toggleTracking) {
                        Image(systemName: followUser ? "location.fill" : "location")
                            .font(.system(size: 18))
                            .foregroundColor(followUser ? hudSettings.hudColor : .gray)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(followUser ? hudSettings.hudColor.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom info panel
                VStack(spacing: 8) {
                    // Stats
                    HStack(spacing: 16) {
                        StatBox(
                            icon: "mappin.circle.fill",
                            value: "\(filteredPOIs.count)",
                            label: "POIs",
                            color: hudSettings.hudColor
                        )
                        
                        if let altitude = locationManager.altitude {
                            StatBox(
                                icon: "arrow.up.circle.fill",
                                value: String(format: "%.0f", altitude),
                                label: "ALT (m)",
                                color: hudSettings.hudColor
                            )
                        }
                        
                        StatBox(
                            icon: "ruler.fill",
                            value: String(format: "%.1f", hudSettings.maxPOIDistance / 1000),
                            label: "RNG (km)",
                            color: hudSettings.hudColor
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Location info
                    if let street = locationManager.currentStreet {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(street)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                
                                if let city = locationManager.currentCity {
                                    Text(city)
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .opacity(0.7)
                                }
                            }
                        }
                        .foregroundColor(hudSettings.hudColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateRegion()
        }
        .onChange(of: locationManager.location) { _ in
            if followUser {
                updateRegion()
            }
        }
    }
    
    private func updateRegion() {
        guard let location = locationManager.location else { return }
        
        // Calculate zoom level based on max distance
        let span = MKCoordinateSpan(
            latitudeDelta: (hudSettings.maxPOIDistance / 111000) * 2.5,
            longitudeDelta: (hudSettings.maxPOIDistance / 111000) * 2.5
        )
        
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: span
        )
    }
    
    private func toggleTracking() {
        followUser.toggle()
        if followUser {
            updateRegion()
        }
    }
}

// MARK: - POI Map Marker

struct POIMapMarker: View {
    let poi: POIData
    let hudSettings: HUDSettings
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color(poi.category.color))
                    .frame(width: 28, height: 28)
                    .blur(radius: 6)
                    .opacity(0.7)
                
                // Icon background
                Circle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 24, height: 24)
                
                // Icon
                Image(systemName: poi.category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(poi.category.color))
            }
            .overlay(
                Circle()
                    .stroke(Color(poi.category.color), lineWidth: 2)
                    .frame(width: 24, height: 24)
            )
            
            // Name label
            Text(poi.name)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.9))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(poi.category.color).opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black, radius: 2)
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct TacticalMapView_Previews: PreviewProvider {
    static var previews: some View {
        TacticalMapView(
            hudSettings: HUDSettings(),
            locationManager: LocationDataManager()
        )
    }
}
