import Foundation
import SwiftData

@Model
final class UserPreferences {
    var bedtime: Date
    var wakeBufferMinutes: Int = 30 // Buffer time after sunrise (0-120 minutes)
    var hasCompletedOnboarding: Bool
    var useManualSunrise: Bool = false // Whether to use manual sunrise time instead of location
    var manualSunriseTime: Date? // User-defined sunrise time when location is disabled
    var createdAt: Date
    var updatedAt: Date
    
    init(
        bedtime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date(), // Default 9 PM
        wakeBufferMinutes: Int = 30, // Default 30 minute buffer after sunrise
        hasCompletedOnboarding: Bool = false,
        useManualSunrise: Bool = false,
        manualSunriseTime: Date? = nil
    ) {
        self.bedtime = bedtime
        self.wakeBufferMinutes = wakeBufferMinutes
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.useManualSunrise = useManualSunrise
        self.manualSunriseTime = manualSunriseTime ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) // Default 7 AM
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func updateBedtime(_ bedtime: Date) {
        self.bedtime = bedtime
        self.updatedAt = Date()
    }
    
    func updateWakeBuffer(_ minutes: Int) {
        self.wakeBufferMinutes = max(0, min(120, minutes)) // Clamp between 0-120
        self.updatedAt = Date()
    }

    func updateManualSunrise(_ time: Date) {
        self.manualSunriseTime = time
        self.useManualSunrise = true
        self.updatedAt = Date()
    }

    func toggleManualSunrise(_ useManual: Bool) {
        self.useManualSunrise = useManual
        self.updatedAt = Date()
    }
}