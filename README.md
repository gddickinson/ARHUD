# AR HUD - Augmented Reality Heads-Up Display

A sci-fi inspired AR app that overlays real-time contextual information on the camera view, including horizon lines, compass directions, nearby points of interest, and more.

## Features

### 🎯 Core Overlays
- **Horizon Line** - Visual horizon indicator with tick marks
- **Compass Rose** - 360° compass with cardinal directions
- **Crosshair** - Center reticle for targeting
- **Grid Overlay** - Optional grid pattern for alignment
- **Status Display** - Altitude, coordinates, and location data

### 📍 Points of Interest (POI)
- Automatic detection of nearby landmarks, restaurants, parks, and transit
- Real-time distance and bearing calculations
- Categorized icons and color coding
- Configurable detection radius (500m - 5km)
- Smart filtering based on category

### 🎨 Customization
- Adjustable HUD color (default: cyan)
- Opacity control (30% - 100%)
- Toggle individual overlays on/off
- Filter POI categories
- Show/hide distance and bearing info

### 📱 Requirements
- iPhone with ARKit support (iPhone 6s or later)
- iOS 14.0 or later
- GPS and location services
- Camera permissions

## Installation

1. Open the project in Xcode 14 or later
2. Select your development team in project settings
3. Build and run on a physical device (AR requires hardware)

**Note:** AR features require a physical device and will not work in the simulator.

## Usage

### First Launch
1. Grant camera and location permissions when prompted
2. Point your iPhone at the horizon
3. Watch the HUD overlay appear with real-time information

### Controls

#### Quick Toggle Buttons (Right Side)
- **Scope Icon** - Toggle horizon line
- **Safari Icon** - Toggle compass
- **Building Icon** - Toggle POI markers
- **Mountain Icon** - Toggle terrain features

#### Settings Menu (Top Left)
- Access full configuration options
- Customize HUD appearance
- Filter POI categories
- Adjust detection radius

### Understanding the Display

**Horizon Line**
- Horizontal dashed line at screen center
- Tick marks every ~30 degrees
- Helps maintain level orientation

**Compass Rose**
- Centered at top of screen
- Red "N" indicator for north
- Current heading in degrees
- Rotates as you turn

**POI Markers**
- Appear in direction of nearby places
- Icon indicates category (building, fork/knife, tree, etc.)
- Distance shown in meters or kilometers
- Bearing angle from current heading
- Vertical position indicates approximate distance (closer = lower on screen)

**Status Bar (Top Right)**
- Altitude above sea level
- GPS coordinates (latitude, longitude)
- Can be toggled on/off

**Center Crosshair**
- Fixed targeting reticle
- Helps identify what you're looking at
- Surrounded by subtle ring

## Architecture

### File Structure
```
ARHUD/
├── ARHUDApp.swift              # App entry point
├── ARHUDView.swift             # Main container view
├── ARCameraView.swift          # ARKit camera implementation
├── HUDOverlayView.swift        # All HUD drawing components
├── HUDSettings.swift           # Settings model
├── LocationDataManager.swift   # GPS, heading, POI detection
├── SettingsView.swift          # Configuration UI
└── Info.plist                  # Permissions and requirements
```

### Key Technologies
- **ARKit** - Camera tracking and world alignment
- **CoreLocation** - GPS, heading, altitude
- **MapKit** - POI discovery and search
- **SwiftUI** - Modern declarative UI
- **Combine** - Reactive data flow

## Customization Examples

### Change HUD Color
```swift
hudSettings.hudColor = .green  // Matrix-style
hudSettings.hudColor = .orange // Warning/tactical
hudSettings.hudColor = .cyan   // Default sci-fi
```

### Adjust POI Range
```swift
hudSettings.maxPOIDistance = 1000  // 1 km radius
hudSettings.maxPOIDistance = 5000  // 5 km radius
```

### Filter Specific Categories
```swift
hudSettings.showLandmarks = true
hudSettings.showRestaurants = false
hudSettings.showParks = true
hudSettings.showTransit = false
```

## Performance Tips

1. **POI Updates**: POI data updates when location changes significantly to avoid excessive API calls
2. **Battery Usage**: AR tracking uses significant battery - keep device charged for extended use
3. **GPS Accuracy**: Works best outdoors with clear view of sky
4. **Heading Calibration**: Wave phone in figure-8 pattern if compass seems inaccurate

## Troubleshooting

**POI markers not appearing:**
- Check location permissions are granted
- Ensure you're in an area with known landmarks
- Increase max POI distance in settings
- Verify internet connection for MapKit queries

**Compass not accurate:**
- Move away from magnetic interference (cars, buildings)
- Calibrate by waving phone in figure-8 motion
- Check Location Services are enabled

**Horizon line off-center:**
- Hold phone level to calibrate
- ARKit uses gravity to determine true horizon

**App crashes on launch:**
- Ensure running on physical device (not simulator)
- Verify camera and location permissions
- Check device supports ARKit

## Future Enhancements

Potential features for future versions:
- Terrain elevation profiles
- Street name overlay using reverse geocoding
- Building wireframe outlines
- Distance measurement tool
- Screenshot/recording capability
- Night mode with different color schemes
- 3D terrain mesh visualization
- Historical landmark information
- Astronomy mode (stars, planets)
- Weather data overlay

## Privacy

This app:
- ✅ Only requests location when in use
- ✅ Does not store or transmit location data
- ✅ Does not record camera footage
- ✅ POI queries are anonymous via MapKit
- ✅ All processing happens on-device


