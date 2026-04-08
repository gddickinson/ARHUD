//
//  LocationDataManager.swift
//  ARHUD
//
//  Manages GPS, heading, altitude, and nearby POI data
//

import Foundation
import CoreLocation
import MapKit
import Combine

class LocationDataManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var heading: CLLocationDirection?
    @Published var altitude: Double?
    @Published var nearbyPOIs: [POIData] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var cameraPitch: Double = 0.0  // Pitch angle in radians from ARKit
    @Published var currentStreet: String?
    @Published var currentCity: String?
    
    private var lastPOIUpdateLocation: CLLocation?
    private var lastPOIUpdateTime: Date?
    private var isUpdatingPOIs = false
    private var poiUpdateTimer: Timer?
    
    private var headingHistory: [CLLocationDirection] = []
    private let headingSmoothingWindow = 5  // Average over last 5 readings
    
    var smoothedHeading: CLLocationDirection {
        guard !headingHistory.isEmpty else { return heading ?? 0 }
        let sum = headingHistory.reduce(0, +)
        return sum / Double(headingHistory.count)
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
        
        // Start periodic POI update checker (every 20 seconds)
        poiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.checkAndUpdatePOIs()
        }
    }
    
    deinit {
        poiUpdateTimer?.invalidate()
    }
    
    // Periodic check to update POIs if needed
    private func checkAndUpdatePOIs() {
        // Use default distance of 2000m for automatic updates
        if shouldUpdatePOIs(maxDistance: 2000) {
            updateNearbyPOIs(maxDistance: 2000)
        }
    }
    
    func updateStreetName() {
        guard let location = location else { return }
        
        // Note: CLGeocoder is deprecated in iOS 26.0 but still functional
        // MapKit alternative would be MKReverseGeocodingRequest (future enhancement)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.currentStreet = placemark.thoroughfare
                self?.currentCity = placemark.locality
            }
        }
    }
    
    // Check if POI update is needed based on location change and time
    func shouldUpdatePOIs(maxDistance: Double) -> Bool {
        // Don't update if already updating
        guard !isUpdatingPOIs else { return false }
        
        // Always update if we've never updated before
        guard let lastLocation = lastPOIUpdateLocation,
              let lastTime = lastPOIUpdateTime else {
            return true
        }
        
        // Check if enough time has passed (minimum 30 seconds between updates)
        let timeSinceLastUpdate = Date().timeIntervalSince(lastTime)
        guard timeSinceLastUpdate > 30 else { return false }
        
        // Check if we've moved significantly (at least 150 meters)
        guard let currentLocation = location else { return false }
        let distanceMoved = currentLocation.distance(from: lastLocation)
        
        return distanceMoved > 150
    }
    
    func updateNearbyPOIs(maxDistance: Double) {
        guard let userLocation = location else { return }
        
        // Check if update is needed
        guard shouldUpdatePOIs(maxDistance: maxDistance) else {
            print("📍 POI update skipped (too soon or already updating)")
            return
        }
        
        // Mark as updating
        isUpdatingPOIs = true
        lastPOIUpdateLocation = userLocation
        lastPOIUpdateTime = Date()
        
        print("📍 Starting POI search from \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        // Keep existing POIs while searching for new ones
        var allPOIs: [POIData] = nearbyPOIs  // Start with existing POIs
        
        // Create dispatch group to wait for all searches
        let searchGroup = DispatchGroup()
        
        // Search categories - run multiple targeted searches
        let searchQueries = [
            "landmarks",
            "restaurants",
            "cafes", 
            "parks",
            "museums",
            "hotels",
            "shopping",
            "attractions",
            "monuments",
            "viewpoints",
            "churches",
            "historic sites",
            "tourist attractions"
        ]
        
        for query in searchQueries {
            searchGroup.enter()
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: userLocation.coordinate,
                latitudinalMeters: maxDistance * 2,
                longitudinalMeters: maxDistance * 2
            )
            
            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                defer { searchGroup.leave() }
                
                guard let self = self,
                      let response = response,
                      error == nil else { return }
                
                let items = response.mapItems.compactMap { item -> POIData? in
                    // In iOS 26+, use item.location instead of deprecated item.placemark.location
                    // Fallback to placemark for older iOS versions
                    let itemLocation: CLLocation?
                    if #available(iOS 26.0, *) {
                        itemLocation = item.location
                    } else {
                        itemLocation = item.placemark.location
                    }
                    
                    guard let poiLocation = itemLocation else { return nil }
                    
                    let distance = userLocation.distance(from: poiLocation)
                    guard distance <= maxDistance else { return nil }
                    
                    let bearing = self.calculateBearing(
                        from: userLocation.coordinate,
                        to: poiLocation.coordinate
                    )
                    
                    return POIData(
                        name: item.name ?? "Unknown",
                        category: self.categorize(item),
                        coordinate: poiLocation.coordinate,
                        distance: distance,
                        bearing: bearing,
                        altitude: poiLocation.altitude
                    )
                }
                
                DispatchQueue.main.async {
                    allPOIs.append(contentsOf: items)
                }
            }
        }
        
        // When all searches complete, deduplicate and update
        searchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Remove duplicates (same location within 50m)
            var uniquePOIs: [POIData] = []
            for poi in allPOIs {
                let isDuplicate = uniquePOIs.contains { existing in
                    let poiLoc = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
                    let existingLoc = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
                    return poiLoc.distance(from: existingLoc) < 50 && poi.name == existing.name
                }
                if !isDuplicate {
                    uniquePOIs.append(poi)
                }
            }
            
            // Remove POIs that are now too far away (beyond maxDistance * 1.5)
            let currentLocation = self.location ?? userLocation
            let filteredPOIs = uniquePOIs.filter { poi in
                let poiLoc = CLLocation(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
                return currentLocation.distance(from: poiLoc) <= maxDistance * 1.5
            }
            
            // Sort by distance and take top 30
            let sortedPOIs = filteredPOIs.sorted { $0.distance < $1.distance }.prefix(30)
            self.nearbyPOIs = Array(sortedPOIs)
            
            self.isUpdatingPOIs = false
            
            print("📍 POI search complete: \(self.nearbyPOIs.count) POIs")
        }
    }
    
    private func categorize(_ item: MKMapItem) -> POICategory {
        let pointOfInterestCategory = item.pointOfInterestCategory
        let name = item.name?.lowercased() ?? ""
        
        // Check explicit POI category first
        switch pointOfInterestCategory {
        case .restaurant, .cafe, .bakery, .brewery, .winery, .foodMarket:
            return .restaurant
        case .park, .nationalPark, .beach, .campground:
            return .park
        case .publicTransport, .airport:
            return .transit
        case .museum, .theater, .landmark, .library, .university, .castle, .fortress:
            return .landmark
        case .hotel, .store, .gasStation, .atm, .bank, .hospital, .pharmacy:
            return .other
        default:
            break
        }
        
        // Fallback to name-based categorization
        if name.contains("park") || name.contains("garden") || name.contains("beach") || 
           name.contains("trail") || name.contains("nature") || name.contains("forest") {
            return .park
        }
        if name.contains("museum") || name.contains("gallery") || name.contains("monument") || 
           name.contains("memorial") || name.contains("historic") || name.contains("castle") ||
           name.contains("church") || name.contains("cathedral") || name.contains("temple") {
            return .landmark
        }
        if name.contains("restaurant") || name.contains("cafe") || name.contains("coffee") || 
           name.contains("bar") || name.contains("grill") || name.contains("pizza") ||
           name.contains("bistro") {
            return .restaurant
        }
        if name.contains("station") || name.contains("stop") || name.contains("terminal") ||
           name.contains("subway") || name.contains("train") || name.contains("bus") {
            return .transit
        }
        
        return .other
    }
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationDataManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.location = location
            self.altitude = location.altitude
            
            // Update street name periodically
            self.updateStreetName()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            let headingValue = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            
            DispatchQueue.main.async {
                self.heading = headingValue
                
                // Add to smoothing history
                self.headingHistory.append(headingValue)
                if self.headingHistory.count > self.headingSmoothingWindow {
                    self.headingHistory.removeFirst()
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            // Trigger initial POI update when authorized
            if manager.authorizationStatus == .authorizedWhenInUse || 
               manager.authorizationStatus == .authorizedAlways {
                // Give location a moment to acquire
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.updateNearbyPOIs(maxDistance: 2000)
                }
            }
        }
    }
}

// MARK: - POI Data Model

struct POIData: Identifiable {
    let id: String
    let name: String
    let category: POICategory
    let coordinate: CLLocationCoordinate2D
    let distance: Double
    let bearing: Double
    let altitude: Double
    
    init(name: String, category: POICategory, coordinate: CLLocationCoordinate2D, distance: Double, bearing: Double, altitude: Double) {
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.distance = distance
        self.bearing = bearing
        self.altitude = altitude
        
        // Create stable ID based on name and rounded location
        // This ensures same POI gets same ID across updates
        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)
        self.id = "\(name)-\(lat)-\(lon)"
    }
}

enum POICategory {
    case landmark
    case restaurant
    case park
    case transit
    case other
    
    var icon: String {
        switch self {
        case .landmark: return "building.columns"
        case .restaurant: return "fork.knife"
        case .park: return "tree"
        case .transit: return "tram"
        case .other: return "mappin"
        }
    }
    
    var color: UIColor {
        switch self {
        case .landmark: return .systemYellow
        case .restaurant: return .systemOrange
        case .park: return .systemGreen
        case .transit: return .systemBlue
        case .other: return .systemGray
        }
    }
}
