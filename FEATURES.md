# AR HUD Features Guide

## Complete Feature Breakdown

### 1. Horizon Line System

**What It Does**
- Displays a horizontal reference line at true horizon
- Uses ARKit gravity alignment for accuracy
- Helps maintain level camera orientation

**Visual Elements**
- Main dashed line across screen center
- Tick marks every ~30 degrees of rotation
- "HORIZON" label on right side
- Cyan color (customizable)

**Use Cases**
- Marine navigation reference
- Photography leveling
- Construction/surveying alignment
- Flight attitude reference

**Settings**
- Toggle: On/Off
- Affected by: HUD color, opacity

---

### 2. Compass Rose

**What It Does**
- Shows current heading in degrees (0-360°)
- Displays 8 cardinal directions (N, NE, E, SE, S, SW, W, NW)
- Rotates based on device magnetometer

**Visual Elements**
- Circular compass ring (120pt diameter)
- Direction labels that counter-rotate
- Red "N" indicator for north
- Fixed red triangle at top (heading indicator)
- Numeric heading display in center

**Use Cases**
- Navigation and orientation
- Determining bearing to landmarks
- Photo/video direction logging
- Hiking and wayfinding

**Settings**
- Toggle: On/Off
- Affected by: HUD color, opacity
- Requires: Location services, magnetometer

**Accuracy Tips**
- Wave phone in figure-8 to calibrate magnetometer
- Move away from metal objects and electronics
- Works better outdoors vs. indoors

---

### 3. Points of Interest (POI) System

**What It Does**
- Queries MapKit for nearby places
- Displays markers in real-world direction
- Shows distance and bearing to each POI
- Updates based on location changes

**Visual Elements**
- Category-specific icons in circles
- Name label below icon
- Distance in meters/kilometers
- Bearing in degrees
- Colored borders by category
- Vertical indicator line to horizon

**POI Categories**

| Category | Icon | Color | Examples |
|----------|------|-------|----------|
| Landmarks | Building columns | Yellow | Museums, monuments, libraries |
| Restaurants | Fork & knife | Orange | Cafes, restaurants, bakeries |
| Parks | Tree | Green | Parks, beaches, nature areas |
| Transit | Tram | Blue | Bus stops, train stations |
| Other | Map pin | Gray | General points |

**Position Calculation**
- Horizontal: Based on bearing relative to heading (±60° FOV)
- Vertical: Based on distance (closer = lower on screen)
- Only shows POI within field of view

**Settings**
- Toggle: Overall POI display
- Filter: By individual category
- Distance: 500m to 5000m radius
- Show/hide distance values
- Show/hide bearing values

**Performance**
- Queries limited to 20 POI
- Updates when location changes ~100m
- Requires internet for initial query
- Results cached locally

---

### 4. Grid Overlay

**What It Does**
- Displays reference grid over camera view
- 8x8 grid pattern
- Helps with composition and alignment

**Visual Elements**
- Thin dashed lines
- Low opacity (30% of HUD opacity)
- Equal spacing horizontally and vertically

**Use Cases**
- Rule of thirds composition
- Architectural alignment
- Symmetry checking
- Reference measurements

**Settings**
- Toggle: On/Off
- Affected by: HUD color, opacity

---

### 5. Center Crosshair

**What It Does**
- Marks exact screen center
- Always visible targeting reticle
- Reference point for all overlays

**Visual Elements**
- 4-line crosshair with gaps
- Center dot (4pt diameter)
- Outer circle (50pt diameter, low opacity)
- Precise center alignment

**Use Cases**
- Targeting and aiming
- Photo center reference
- Measuring angles
- Direction finding

**Settings**
- Always visible (no toggle)
- Affected by: HUD color, opacity

---

### 6. Status Bar

**What It Does**
- Displays real-time location metrics
- Shows altitude and coordinates
- Updates with GPS

**Displayed Information**

**Altitude**
- Meters above sea level
- Based on GPS elevation
- Icon: Up arrow
- Format: "123 m"

**Coordinates**
- Latitude and longitude
- 4 decimal precision (~11m accuracy)
- Format: "37.7749°, -122.4194°"

**Settings**
- Toggle altitude: On/Off
- Toggle coordinates: On/Off
- Affected by: HUD color, opacity

**Accuracy**
- GPS accuracy: 5-10m typical
- Altitude accuracy: 10-20m typical
- Updates every 1-2 seconds

---

### 7. Quick Toggle Controls

**Location**: Right side of screen

**Buttons**
1. **Scope** (⊕) - Horizon line
2. **Safari** (⊙) - Compass rose
3. **Buildings** (🏢) - POI markers
4. **Mountains** (⛰️) - Terrain features

**Visual States**
- Active: Cyan with glow
- Inactive: Gray, dim
- Each 44x44 touch target

---

### 8. Settings Menu

**Access**: Slider icon, top left

**Sections**

**Overlays**
- Individual toggles for all major features
- Quick enable/disable

**Status Display**
- Toggle altitude, coordinates, distance, bearing
- Control what information is shown

**POI Filters**
- Per-category filtering
- Landmarks, restaurants, parks, transit

**Appearance**
- HUD color picker (any color)
- Opacity slider (30-100%)
- Max POI distance (500-5000m)

**Reset**
- Restore default settings
- Cyan, 80% opacity, 2km radius

---

## Advanced Features

### Field of View Calculation

POI markers use a 60° horizontal field of view:
- Center: 0° offset from heading
- Left edge: -30° from heading
- Right edge: +30° from heading

This approximates iPhone camera FOV for realistic positioning.

### Distance Rendering

POI vertical position indicates distance:
```
Close (0m):     40% down screen
Medium (1km):   50% down screen  
Far (2km):      60% down screen
```

Creates depth perception effect.

### Bearing Calculation

Uses great circle formula:
```
bearing = atan2(
    sin(Δλ) × cos(φ₂),
    cos(φ₁) × sin(φ₂) - sin(φ₁) × cos(φ₂) × cos(Δλ)
)
```

Accurate for navigation purposes.

### Update Intervals

| Data Type | Update Rate | Trigger |
|-----------|-------------|---------|
| Camera | 60 fps | ARKit frame |
| Heading | ~5 Hz | Magnetometer |
| GPS | ~1 Hz | Location change |
| POI | On demand | 100m movement |

---

## Usage Scenarios

### Urban Exploration
- Enable: POI, Compass, Coordinates
- Filter: Landmarks, Restaurants
- Distance: 1-2 km

### Hiking/Nature
- Enable: Horizon, Compass, Altitude
- Filter: Parks, Terrain
- Distance: 2-5 km

### Photography
- Enable: Grid, Horizon, Coordinates
- Disable: POI (less clutter)
- For composition and location logging

### Navigation
- Enable: Compass, POI, Street Names
- Filter: Transit, Landmarks
- Distance: 500-1000m
- For wayfinding

### Architecture/Construction
- Enable: Grid, Horizon
- Disable: POI, Compass
- For alignment and leveling

---

## Customization Tips

### Sci-Fi Themes

**Cyberpunk**
- Color: Magenta or purple
- Opacity: 100%
- All overlays enabled

**Military/Tactical**
- Color: Green
- Opacity: 70%
- Minimal POI

**Iron Man JARVIS**
- Color: Cyan (default)
- Opacity: 80%
- All features enabled

**Minimalist**
- Color: White or gray
- Opacity: 50%
- Only horizon and crosshair

### Low Light Optimization
- Reduce opacity to 40-50%
- Disable grid (less clutter)
- Enable only essential overlays

### High Density Areas
- Reduce POI distance to 500-1000m
- Filter to 1-2 categories only
- Prevents screen crowding

---

## Performance Characteristics

### Battery Impact
- ARKit tracking: High (~20% per hour)
- GPS updates: Medium (~5% per hour)
- MapKit queries: Low (minimal)

### Data Usage
- POI queries: ~100KB per update
- No continuous streaming
- Works offline after initial query

### Processing Load
- ARKit: GPU-intensive
- Rendering: Moderate CPU
- Location: Minimal overhead

---

## Troubleshooting by Feature

**Horizon off-center**
→ Hold level, ARKit auto-calibrates

**Compass spinning**
→ Magnetic interference, move location

**No POI appearing**
→ Check permissions, internet, increase radius

**Crosshair not centered**
→ Should be perfect, report if not

**Grid not visible**
→ May be too faint, increase opacity

**Altitude shows 0m**
→ GPS needs time to acquire, wait 30s

**Coordinates not updating**
→ Check location permissions, try outdoors

---

## API Integration Points

For developers extending this app:

**Add Custom POI**
```swift
// Add custom POIData objects to locationManager.nearbyPOIs
let customPOI = POIData(
    name: "Custom Location",
    category: .landmark,
    coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
    distance: 1000,
    bearing: 45,
    altitude: 100
)
```

**Custom Overlay Layers**
```swift
// Add new view to HUDOverlayView ZStack
if hudSettings.showCustomOverlay {
    CustomOverlayView(hudSettings: hudSettings)
}
```

**Access AR Camera Data**
```swift
// Available in ARSessionDelegate
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    let cameraTransform = frame.camera.transform
    // Use for advanced calculations
}
```

---

This HUD system provides a comprehensive AR overlay platform suitable for navigation, exploration, photography, and general situational awareness. All features work together to create an immersive augmented reality experience.
