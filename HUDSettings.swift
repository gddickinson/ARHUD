//
//  HUDSettings.swift
//  ARHUD
//
//  Settings for HUD overlays
//

import Foundation
import SwiftUI
import Combine

class HUDSettings: ObservableObject {
    // Overlay toggles
    @Published var showHorizon = true
    @Published var showCompass = true
    @Published var showPOI = true
    @Published var showTerrain = true
    @Published var showStreetNames = true
    @Published var showGrid = false
    @Published var showAltitude = true
    @Published var showCoordinates = true
    
    // Display options
    @Published var hudColor: Color = .cyan
    @Published var hudOpacity: Double = 0.8
    @Published var maxPOIDistance: Double = 2000 // meters
    @Published var showDistance = true
    @Published var showBearing = true
    
    // POI filters
    @Published var showLandmarks = true
    @Published var showRestaurants = true
    @Published var showParks = true
    @Published var showTransit = true
    
    var hudColorUIColor: UIColor {
        UIColor(hudColor)
    }
    
    var hudColorCGColor: CGColor {
        hudColorUIColor.cgColor
    }
}
