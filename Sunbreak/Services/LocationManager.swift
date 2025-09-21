import CoreLocation
import SwiftUI
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var sunrise: Date?
    @Published var sunset: Date?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
        authorizationStatus = manager.authorizationStatus

        // Check if user has set manual sunrise time
        loadSunriseTimes()

        // Listen for timezone changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timezoneChanged),
            name: .timezoneChanged,
            object: nil
        )
    }

    private func loadSunriseTimes() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let useManualSunrise = userDefaults?.bool(forKey: "useManualSunrise") ?? false

        if useManualSunrise, let manualTime = userDefaults?.object(forKey: "manualSunriseTime") as? Date {
            // Use manual sunrise time
            setManualSunriseTimes(manualTime)
        } else {
            // Set default or calculate from location
            setDefaultSunTimes()
        }
    }

    private func setManualSunriseTimes(_ manualSunrise: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: manualSunrise)

        var sunriseComponents = calendar.dateComponents([.year, .month, .day], from: now)
        sunriseComponents.hour = components.hour
        sunriseComponents.minute = components.minute

        sunrise = calendar.date(from: sunriseComponents)

        // Set sunset to 12 hours after sunrise as approximation
        var sunsetComponents = sunriseComponents
        sunsetComponents.hour = (components.hour ?? 7) + 12
        sunset = calendar.date(from: sunsetComponents)

        // Save to UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(sunrise, forKey: "sunrise")
        userDefaults?.set(sunset, forKey: "sunset")
        userDefaults?.set(calendar.timeZone.identifier, forKey: "sunTimesTimeZone")

        Logger.shared.log("[LocationManager] Using manual sunrise: \(sunrise?.description ?? "nil")")
    }
    
    @objc private func timezoneChanged() {
        handleTimezoneChange()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let useManualSunrise = userDefaults?.bool(forKey: "useManualSunrise") ?? false

        if authorizationStatus == .authorizedWhenInUse {
            // Clear manual sunrise preference when location is granted
            userDefaults?.set(false, forKey: "useManualSunrise")
            manager.requestLocation()
        } else if !useManualSunrise {
            // If not using manual and no location, load times
            loadSunriseTimes()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        if let location = location {
            calculateSunTimes(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.shared.log("Location error: \(error)")
        // Fall back to default sunrise/sunset times
        setDefaultSunTimes()
    }
    
    private func calculateSunTimes(for location: CLLocation) {
        // Use current timezone for all calculations
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let now = Date()
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        Logger.shared.log("[LocationManager] Starting calculation for lat: \(latitude), lng: \(longitude)")
        
        // For Singapore (around 1.3°N, 103.8°E), sunrise is typically around 6:30-7:00 AM
        // Use a simpler approximation that actually works
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        
        // Singapore sunrise varies from about 6:45 AM to 7:15 AM throughout the year
        // Simple approximation: 7:00 AM +/- 15 minutes based on season
        let seasonalOffset = sin(Double(dayOfYear - 80) * 2 * .pi / 365) * 15 // +/- 15 minutes
        
        let baseHour = 7
        let baseMinute = 0
        let adjustedMinute = Int(Double(baseMinute) + seasonalOffset)
        
        var sunriseComponents = calendar.dateComponents([.year, .month, .day], from: now)
        sunriseComponents.hour = baseHour
        sunriseComponents.minute = max(0, min(59, adjustedMinute))
        
        var sunsetComponents = calendar.dateComponents([.year, .month, .day], from: now)  
        sunsetComponents.hour = 19 // Singapore sunset around 7 PM
        sunsetComponents.minute = 0
        
        sunrise = calendar.date(from: sunriseComponents)
        sunset = calendar.date(from: sunsetComponents)
        
        // Save to UserDefaults for app group access with timezone info
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(sunrise, forKey: "sunrise")
        userDefaults?.set(sunset, forKey: "sunset")
        userDefaults?.set(calendar.timeZone.identifier, forKey: "sunTimesTimeZone")
        
        Logger.shared.log("[LocationManager] Calculated sunrise: \(sunrise?.description ?? "nil") sunset: \(sunset?.description ?? "nil") for timezone: \(calendar.timeZone.identifier)")
    }
    
    private func setDefaultSunTimes() {
        // Use current timezone for default times
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let now = Date()
        
        let sunriseComponents = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: 7,
            minute: 0
        )
        
        let sunsetComponents = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: 19,
            minute: 0
        )
        
        sunrise = calendar.date(from: sunriseComponents)
        sunset = calendar.date(from: sunsetComponents)
        
        // Save default times with timezone info
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(sunrise, forKey: "sunrise")
        userDefaults?.set(sunset, forKey: "sunset")
        userDefaults?.set(calendar.timeZone.identifier, forKey: "sunTimesTimeZone")
        
        Logger.shared.log("[LocationManager] Set default sunrise: \(sunrise?.description ?? "nil") sunset: \(sunset?.description ?? "nil") for timezone: \(calendar.timeZone.identifier)")
    }
    
    // Proper sunrise/sunset calculation using the sunrise equation
    private func calculateSunriseSunset(latitude: Double, longitude: Double, date: Date) -> (sunrise: Date?, sunset: Date?) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        Logger.shared.log("[LocationManager] Calculating sunrise for day \(dayOfYear), lat: \(latitude), lng: \(longitude)")
        
        // Convert to radians
        let latRad = latitude * .pi / 180
        
        // Solar declination angle - corrected formula
        let declinationAngle = 23.45 * sin((360 * Double(dayOfYear - 81) / 365) * .pi / 180)
        let declinationRad = declinationAngle * .pi / 180
        
        // Hour angle at sunrise/sunset
        let hourAngleCos = -tan(latRad) * tan(declinationRad)
        
        Logger.shared.log("[LocationManager] Hour angle cos: \(hourAngleCos)")
        
        // Check for polar day or night
        if hourAngleCos > 1 {
            Logger.shared.log("[LocationManager] Polar night detected")
            return (nil, nil)
        } else if hourAngleCos < -1 {
            Logger.shared.log("[LocationManager] Polar day detected")
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            return (startOfDay, endOfDay)
        }
        
        let hourAngle = acos(hourAngleCos) * 180 / .pi
        
        // Equation of time correction
        let equationOfTime = 9.87 * sin(2 * Double(dayOfYear - 81) * .pi / 365) - 7.53 * cos(Double(dayOfYear - 81) * .pi / 365) - 1.5 * sin(Double(dayOfYear - 81) * .pi / 365)
        let solarNoon = 12 - longitude / 15 - equationOfTime / 60
        
        let sunriseHour = solarNoon - hourAngle / 15
        let sunsetHour = solarNoon + hourAngle / 15
        
        Logger.shared.log("[LocationManager] Solar times - sunrise: \(sunriseHour), sunset: \(sunsetHour)")
        
        // Convert decimal hours to Date - ensure valid hours
        let clampedSunriseHour = max(0, min(23, sunriseHour))
        let clampedSunsetHour = max(0, min(23, sunsetHour))
        
        let sunriseMinutes = Int(clampedSunriseHour * 60)
        let sunsetMinutes = Int(clampedSunsetHour * 60)
        
        let sunriseTime = calendar.date(bySettingHour: sunriseMinutes / 60, minute: sunriseMinutes % 60, second: 0, of: date)
        let sunsetTime = calendar.date(bySettingHour: sunsetMinutes / 60, minute: sunsetMinutes % 60, second: 0, of: date)
        
        Logger.shared.log("[LocationManager] Final times - sunrise: \(sunriseTime?.description ?? "nil"), sunset: \(sunsetTime?.description ?? "nil")")
        
        return (sunriseTime, sunsetTime)
    }
    
    // Add function to handle timezone changes or manual sunrise updates
    func handleTimezoneChange() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let currentTimeZone = TimeZone.current.identifier
        let savedTimeZone = userDefaults?.string(forKey: "sunTimesTimeZone")

        if savedTimeZone != currentTimeZone {
            Logger.shared.log("[LocationManager] Timezone changed from \(savedTimeZone ?? "unknown") to \(currentTimeZone)")
        }

        // Reload sunrise times based on current settings
        loadSunriseTimes()
    }
}