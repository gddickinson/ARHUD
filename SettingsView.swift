//
//  SettingsView.swift
//  ARHUD
//
//  HUD configuration and toggles
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var hudSettings: HUDSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("Horizon Line", isOn: $hudSettings.showHorizon)
                    Toggle("Compass Rose", isOn: $hudSettings.showCompass)
                    Toggle("Grid Overlay", isOn: $hudSettings.showGrid)
                    Toggle("Points of Interest", isOn: $hudSettings.showPOI)
                    Toggle("Terrain Features", isOn: $hudSettings.showTerrain)
                    Toggle("Street Names", isOn: $hudSettings.showStreetNames)
                } header: {
                    Text("Overlays")
                }
                
                Section {
                    Toggle("Altitude", isOn: $hudSettings.showAltitude)
                    Toggle("Coordinates", isOn: $hudSettings.showCoordinates)
                    Toggle("Distance", isOn: $hudSettings.showDistance)
                    Toggle("Bearing", isOn: $hudSettings.showBearing)
                } header: {
                    Text("Status Display")
                }
                
                Section {
                    Toggle("Landmarks", isOn: $hudSettings.showLandmarks)
                    Toggle("Restaurants", isOn: $hudSettings.showRestaurants)
                    Toggle("Parks", isOn: $hudSettings.showParks)
                    Toggle("Transit", isOn: $hudSettings.showTransit)
                } header: {
                    Text("POI Filters")
                }
                
                Section {
                    HStack {
                        Text("HUD Color")
                        Spacer()
                        ColorPicker("", selection: $hudSettings.hudColor)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opacity")
                        Slider(value: $hudSettings.hudOpacity, in: 0.3...1.0)
                        Text(String(format: "%.0f%%", hudSettings.hudOpacity * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Max POI Distance")
                        Slider(value: $hudSettings.maxPOIDistance, in: 500...5000, step: 100)
                        Text(String(format: "%.0f meters", hudSettings.maxPOIDistance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Button(action: resetToDefaults) {
                        HStack {
                            Spacer()
                            Text("Reset to Defaults")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("HUD Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resetToDefaults() {
        hudSettings.showHorizon = true
        hudSettings.showCompass = true
        hudSettings.showPOI = true
        hudSettings.showTerrain = true
        hudSettings.showStreetNames = true
        hudSettings.showGrid = false
        hudSettings.showAltitude = true
        hudSettings.showCoordinates = true
        hudSettings.showDistance = true
        hudSettings.showBearing = true
        hudSettings.hudColor = .cyan
        hudSettings.hudOpacity = 0.8
        hudSettings.maxPOIDistance = 2000
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(hudSettings: HUDSettings())
    }
}
