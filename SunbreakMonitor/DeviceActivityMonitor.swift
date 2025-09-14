import DeviceActivity
import ManagedSettings
import FamilyControls
import SwiftUI

class SunbreakMonitor: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        
        // Called when bedtime starts
        if activity.rawValue == "bedtime" {
            applyBedtimeRestrictions()
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        
        // Called when wake time is reached
        if activity.rawValue == "bedtime" {
            // Check if user has unlocked for today
            if !isDayUnlocked() {
                maintainRestrictions()
            } else {
                clearRestrictions()
            }
        }
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // The shield will automatically appear
        // Log the attempt for debugging
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let attempts = userDefaults?.integer(forKey: "shieldAttempts") ?? 0
        userDefaults?.set(attempts + 1, forKey: "shieldAttempts")
        userDefaults?.set(Date(), forKey: "lastShieldAttempt")
    }
    
    private func applyBedtimeRestrictions() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        
        // Load saved selection from app group
        guard let selectionData = userDefaults?.data(forKey: "savedSelection") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let selection = try decoder.decode(FamilyActivitySelection.self, from: selectionData)
            
            
            // Apply shields with validation
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }
            
            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }
            
            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }
            
            // Log successful application
            userDefaults?.set(Date(), forKey: "lastRestrictionApplication")
            
        } catch {
        }
    }
    
    private func maintainRestrictions() {
        // Keep current restrictions active
        // This is called when wake time is reached but user hasn't done daylight unlock
    }
    
    private func clearRestrictions() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    private func isDayUnlocked() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        guard let unlockedDate = userDefaults?.object(forKey: "dayUnlockedFor") as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.isDate(unlockedDate, inSameDayAs: today)
    }
}

// Extension for custom shield configuration (removed - can't override from extension)