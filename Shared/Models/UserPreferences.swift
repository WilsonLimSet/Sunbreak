import Foundation
import SwiftData

@Model
final class UserPreferences {
    var bedtime: Date
    var wakeBufferMinutes: Int = 30 // Buffer time after sunrise (0-120 minutes)
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        bedtime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date(), // Default 9 PM
        wakeBufferMinutes: Int = 30, // Default 30 minute buffer after sunrise
        hasCompletedOnboarding: Bool = false
    ) {
        self.bedtime = bedtime
        self.wakeBufferMinutes = wakeBufferMinutes
        self.hasCompletedOnboarding = hasCompletedOnboarding
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
}