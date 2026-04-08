//
//  ARHUDView.swift
//  ARHUD
//
//  Main AR HUD interface
//

import SwiftUI
import ARKit

struct ARHUDView: View {
    @StateObject private var hudSettings = HUDSettings()
    @StateObject private var locationManager = LocationDataManager()
    @State private var showSettings = false
    @State private var showTacticalMap = false
    
    var body: some View {
        ZStack {
            // AR Camera View
            ARCameraViewRepresentable(
                hudSettings: hudSettings,
                locationManager: locationManager
            )
            .ignoresSafeArea()
            
            // HUD Overlays
            HUDOverlayView(
                hudSettings: hudSettings,
                locationManager: locationManager
            )
            
            // Control Buttons
            VStack {
                HStack {
                    // Settings button
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.cyan)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Tactical Map button
                    Button(action: { showTacticalMap.toggle() }) {
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundColor(.cyan)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Quick toggles
                    VStack(spacing: 12) {
                        QuickToggle(
                            icon: "scope",
                            isOn: hudSettings.showHorizon,
                            action: { hudSettings.showHorizon.toggle() }
                        )
                        
                        QuickToggle(
                            icon: "safari",
                            isOn: hudSettings.showCompass,
                            action: { hudSettings.showCompass.toggle() }
                        )
                        
                        QuickToggle(
                            icon: "building.2",
                            isOn: hudSettings.showPOI,
                            action: { hudSettings.showPOI.toggle() }
                        )
                        
                        QuickToggle(
                            icon: "mountain.2",
                            isOn: hudSettings.showTerrain,
                            action: { hudSettings.showTerrain.toggle() }
                        )
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView(hudSettings: hudSettings)
        }
        .fullScreenCover(isPresented: $showTacticalMap) {
            TacticalMapView(hudSettings: hudSettings, locationManager: locationManager)
        }
        .statusBarHidden()
    }
}

// MARK: - Quick Toggle Button

struct QuickToggle: View {
    let icon: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isOn ? .cyan : .gray)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOn ? Color.cyan.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

struct ARHUDView_Previews: PreviewProvider {
    static var previews: some View {
        ARHUDView()
    }
}
