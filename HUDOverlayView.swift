//
//  HUDOverlayView.swift
//  ARHUD
//
//  Sci-fi HUD overlay with horizon, compass, and POI markers
//

import SwiftUI
import CoreLocation

struct HUDOverlayView: View {
    @ObservedObject var hudSettings: HUDSettings
    @ObservedObject var locationManager: LocationDataManager
    
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
                return true  // Always show "other"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizon line
                if hudSettings.showHorizon {
                    HorizonView(
                        hudSettings: hudSettings,
                        cameraPitch: locationManager.cameraPitch
                    )
                }
                
                // Compass rose
                if hudSettings.showCompass {
                    CompassView(
                        heading: locationManager.heading ?? 0,
                        hudSettings: hudSettings
                    )
                }
                
                // Grid overlay
                if hudSettings.showGrid {
                    GridOverlayView(hudSettings: hudSettings)
                }
                
                // POI markers
                if hudSettings.showPOI {
                    POIMarkersView(
                        pois: filteredPOIs,
                        currentHeading: locationManager.smoothedHeading,
                        hudSettings: hudSettings,
                        screenSize: geometry.size
                    )
                }
                
                // Street name overlay
                if hudSettings.showStreetNames, let street = locationManager.currentStreet {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(street)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                
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
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                        )
                        .opacity(hudSettings.hudOpacity)
                        .padding(.bottom, 100)
                    }
                }
                
                // Status bar at top
                StatusBarView(
                    location: locationManager.location,
                    altitude: locationManager.altitude,
                    heading: locationManager.heading,
                    hudSettings: hudSettings
                )
                
                // Center crosshair
                CenterCrosshairView(hudSettings: hudSettings)
                
                // Debug info (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("POI: \(filteredPOIs.count)/\(locationManager.nearbyPOIs.count)")
                                .font(.system(size: 9, design: .monospaced))
                            Text("GPS: \(locationManager.location != nil ? "✓" : "✗")")
                                .font(.system(size: 9, design: .monospaced))
                            if let heading = locationManager.heading {
                                Text("HDG: \(String(format: "%.0f°", heading))")
                                    .font(.system(size: 9, design: .monospaced))
                            }
                        }
                        .foregroundColor(hudSettings.hudColor.opacity(0.5))
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            // Initial POI update when view appears
            locationManager.updateNearbyPOIs(maxDistance: hudSettings.maxPOIDistance)
        }
        .onChange(of: hudSettings.maxPOIDistance) { newDistance in
            // Force update when distance setting changes
            // Reset the update tracking to allow immediate update
            locationManager.updateNearbyPOIs(maxDistance: newDistance)
        }
    }
}

// MARK: - Horizon View

struct HorizonView: View {
    @ObservedObject var hudSettings: HUDSettings
    let cameraPitch: Double  // Pitch angle in radians
    
    var body: some View {
        GeometryReader { geometry in
            let horizonY = calculateHorizonY(screenHeight: geometry.size.height, pitch: cameraPitch)
            
            ZStack {
                // Main horizon line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: horizonY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: horizonY))
                }
                .stroke(hudSettings.hudColor, style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                .opacity(hudSettings.hudOpacity)
                
                // Tick marks every 30 degrees
                ForEach(-3...3, id: \.self) { i in
                    let x = geometry.size.width / 2 + CGFloat(i) * geometry.size.width / 7
                    
                    if abs(i) != 0 {
                        Path { path in
                            path.move(to: CGPoint(x: x, y: horizonY - 20))
                            path.addLine(to: CGPoint(x: x, y: horizonY + 20))
                        }
                        .stroke(hudSettings.hudColor, lineWidth: 1)
                        .opacity(hudSettings.hudOpacity * 0.5)
                    }
                }
                
                // Horizon label
                Text("HORIZON")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(hudSettings.hudColor)
                    .opacity(hudSettings.hudOpacity)
                    .position(x: geometry.size.width - 50, y: horizonY - 15)
                
                // Sky indicator (above horizon)
                if horizonY > 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                        Text("SKY")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(hudSettings.hudColor)
                    .opacity(hudSettings.hudOpacity * 0.6)
                    .position(x: 40, y: horizonY - 40)
                }
                
                // Ground indicator (below horizon)
                if horizonY < geometry.size.height - 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                        Text("GROUND")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(hudSettings.hudColor)
                    .opacity(hudSettings.hudOpacity * 0.6)
                    .position(x: 50, y: horizonY + 40)
                }
                
                // Pitch angle display (debug/info)
                Text(String(format: "%.1f°", cameraPitch * 180 / .pi))
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(hudSettings.hudColor)
                    .opacity(hudSettings.hudOpacity * 0.5)
                    .position(x: 40, y: horizonY + 5)
            }
        }
    }
    
    // Calculate horizon Y position based on camera pitch
    private func calculateHorizonY(screenHeight: CGFloat, pitch: Double) -> CGFloat {
        // iPhone camera vertical FOV is approximately 60 degrees (1.047 radians)
        let verticalFOV: Double = 1.047  // radians (~60 degrees)
        
        // Calculate how much of the screen the pitch represents
        // Positive pitch (looking up) moves horizon down
        // Negative pitch (looking down) moves horizon up
        let pitchRatio = pitch / (verticalFOV / 2)
        
        // Map to screen coordinates
        // Center is at screenHeight / 2
        // Full range is from 0 to screenHeight
        let offset = CGFloat(pitchRatio) * (screenHeight / 2)
        let horizonY = (screenHeight / 2) + offset
        
        // Clamp to keep horizon on screen
        return max(50, min(screenHeight - 50, horizonY))
    }
}

// MARK: - Compass View

struct CompassView: View {
    let heading: Double
    let hudSettings: HUDSettings
    
    var body: some View {
        VStack {
            ZStack {
                // Compass ring
                Circle()
                    .stroke(hudSettings.hudColor, lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .opacity(hudSettings.hudOpacity * 0.5)
                
                // Cardinal directions
                ForEach(cardinalDirections, id: \.angle) { direction in
                    VStack(spacing: 2) {
                        Text(direction.label)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(direction.label == "N" ? .red : hudSettings.hudColor)
                        
                        Rectangle()
                            .fill(direction.label == "N" ? Color.red : hudSettings.hudColor)
                            .frame(width: 2, height: 12)
                    }
                    .offset(y: -60)
                    .rotationEffect(.degrees(direction.angle - heading))
                }
                
                // Heading indicator (fixed at top)
                VStack(spacing: 0) {
                    Triangle()
                        .fill(Color.red)
                        .frame(width: 16, height: 10)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 20)
                }
                .offset(y: -70)
                
                // Heading value
                Text(String(format: "%.0f°", heading))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(hudSettings.hudColor)
            }
            .opacity(hudSettings.hudOpacity)
            .padding(.top, 80)
            
            Spacer()
        }
    }
    
    private let cardinalDirections = [
        (label: "N", angle: 0.0),
        (label: "NE", angle: 45.0),
        (label: "E", angle: 90.0),
        (label: "SE", angle: 135.0),
        (label: "S", angle: 180.0),
        (label: "SW", angle: 225.0),
        (label: "W", angle: 270.0),
        (label: "NW", angle: 315.0)
    ]
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Grid Overlay

struct GridOverlayView: View {
    let hudSettings: HUDSettings
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                let vSpacing = geometry.size.width / 8
                for i in 1..<8 {
                    let x = vSpacing * CGFloat(i)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                let hSpacing = geometry.size.height / 8
                for i in 1..<8 {
                    let y = hSpacing * CGFloat(i)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(hudSettings.hudColor, style: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
            .opacity(hudSettings.hudOpacity * 0.3)
        }
    }
}

// MARK: - POI Markers

struct POIMarkersView: View {
    let pois: [POIData]
    let currentHeading: Double
    let hudSettings: HUDSettings
    let screenSize: CGSize
    
    // Track which POIs were recently visible for persistence
    @State private var recentlyVisiblePOIs: Set<String> = []
    
    var body: some View {
        ForEach(pois) { poi in
            POIMarker(
                poi: poi,
                currentHeading: currentHeading,
                hudSettings: hudSettings,
                screenSize: screenSize,
                wasRecentlyVisible: recentlyVisiblePOIs.contains(poi.id)
            )
            .onAppear {
                // Mark as visible when it appears
                recentlyVisiblePOIs.insert(poi.id)
            }
        }
        .onChange(of: currentHeading) { _ in
            // Clean up POIs that are way out of view after heading change
            cleanupRecentlyVisible()
        }
    }
    
    private func cleanupRecentlyVisible() {
        // Remove POIs from recent set if they're > 120° away
        let threshold: Double = 120
        recentlyVisiblePOIs = recentlyVisiblePOIs.filter { id in
            if let poi = pois.first(where: { $0.id == id }) {
                var bearingDiff = poi.bearing - currentHeading
                while bearingDiff > 180 { bearingDiff -= 360 }
                while bearingDiff < -180 { bearingDiff += 360 }
                return abs(bearingDiff) < threshold
            }
            return false
        }
    }
}

struct POIMarker: View {
    let poi: POIData
    let currentHeading: Double
    let hudSettings: HUDSettings
    let screenSize: CGSize
    let wasRecentlyVisible: Bool
    
    var body: some View {
        let position = calculateScreenPosition()
        
        if position.isVisible {
            VStack(spacing: 4) {
                // Icon with glow effect
                ZStack {
                    // Glow
                    Circle()
                        .fill(Color(poi.category.color))
                        .frame(width: 32, height: 32)
                        .blur(radius: 8)
                        .opacity(0.6)
                    
                    // Icon background
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 28, height: 28)
                    
                    // Icon
                    Image(systemName: poi.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(poi.category.color))
                }
                .overlay(
                    Circle()
                        .stroke(Color(poi.category.color), lineWidth: 2)
                        .frame(width: 28, height: 28)
                )
                
                // Name and info with improved visibility
                VStack(spacing: 2) {
                    Text(poi.name)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                    
                    if hudSettings.showDistance {
                        Text(formatDistance(poi.distance))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(poi.category.color))
                            .shadow(color: .black, radius: 1)
                    }
                    
                    if hudSettings.showBearing {
                        Text(String(format: "%.0f°", poi.bearing))
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(hudSettings.hudColor.opacity(0.8))
                            .shadow(color: .black, radius: 1)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(poi.category.color).opacity(0.6), lineWidth: 1.5)
                )
                
                // Indicator line to horizon - more visible
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: min(120, position.y - screenSize.height / 2)))
                }
                .stroke(
                    Color(poi.category.color),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                )
                .opacity(0.5)
            }
            .position(x: position.x, y: position.y)
            .opacity(hudSettings.hudOpacity)
        }
    }
    
    private func calculateScreenPosition() -> (x: CGFloat, y: CGFloat, isVisible: Bool) {
        // Calculate bearing difference from current heading
        var bearingDiff = poi.bearing - currentHeading
        
        // Normalize to -180 to 180
        while bearingDiff > 180 { bearingDiff -= 360 }
        while bearingDiff < -180 { bearingDiff += 360 }
        
        // HYSTERESIS: Use different FOV thresholds based on recent visibility
        // Once visible, allow wider range before hiding (sticky behavior)
        let fovShow: Double = 80  // degrees - show if within this angle
        let fovHide: Double = 100 // degrees - hide only if beyond this angle
        
        let fovThreshold = wasRecentlyVisible ? fovHide : fovShow
        
        guard abs(bearingDiff) < fovThreshold else {
            return (0, 0, false)
        }
        
        // Map bearing to horizontal screen position with wider range
        let normalizedBearing = bearingDiff / fovShow // Use show FOV for positioning
        let x = screenSize.width / 2 + CGFloat(normalizedBearing) * screenSize.width * 0.5
        
        // Estimate vertical position based on distance
        // Closer objects appear lower (perspective)
        let distanceFactor = min(1.0, poi.distance / hudSettings.maxPOIDistance)
        let baseY = screenSize.height * 0.35  // Higher base position
        let y = baseY + CGFloat(distanceFactor) * screenSize.height * 0.25
        
        return (x, y, true)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }
}

// MARK: - Status Bar

struct StatusBarView: View {
    let location: CLLocation?
    let altitude: Double?
    let heading: Double?
    let hudSettings: HUDSettings
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if hudSettings.showAltitude, let altitude = altitude {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10))
                            Text(String(format: "%.0f m", altitude))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        }
                    }
                    
                    if hudSettings.showCoordinates, let location = location {
                        Text(String(format: "%.4f°, %.4f°",
                                  location.coordinate.latitude,
                                  location.coordinate.longitude))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                    }
                }
                .foregroundColor(hudSettings.hudColor)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hudSettings.hudColor.opacity(0.5), lineWidth: 1)
                )
            }
            .padding()
            
            Spacer()
        }
        .opacity(hudSettings.hudOpacity)
    }
}

// MARK: - Center Crosshair

struct CenterCrosshairView: View {
    let hudSettings: HUDSettings
    
    var body: some View {
        ZStack {
            // Center dot
            Circle()
                .fill(hudSettings.hudColor)
                .frame(width: 4, height: 4)
            
            // Crosshair lines
            Path { path in
                path.move(to: CGPoint(x: -20, y: 0))
                path.addLine(to: CGPoint(x: -5, y: 0))
                
                path.move(to: CGPoint(x: 5, y: 0))
                path.addLine(to: CGPoint(x: 20, y: 0))
                
                path.move(to: CGPoint(x: 0, y: -20))
                path.addLine(to: CGPoint(x: 0, y: -5))
                
                path.move(to: CGPoint(x: 0, y: 5))
                path.addLine(to: CGPoint(x: 0, y: 20))
            }
            .stroke(hudSettings.hudColor, lineWidth: 1.5)
            
            // Outer circle
            Circle()
                .stroke(hudSettings.hudColor, lineWidth: 1)
                .frame(width: 50, height: 50)
                .opacity(0.3)
        }
        .opacity(hudSettings.hudOpacity)
    }
}
