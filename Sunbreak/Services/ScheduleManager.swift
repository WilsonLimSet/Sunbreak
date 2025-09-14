import Foundation
import FamilyControls
import ManagedSettings
import SwiftData

extension Notification.Name {
    static let timezoneChanged = Notification.Name("timezoneChanged")
}

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    private let store = ManagedSettingsStore()
    private var scheduleTimer: Timer?
    
    @Published var isInBedtime: Bool = false
    @Published var isDayUnlocked: Bool = false
    
    private init() {
        evaluateCurrentState()
        startScheduleTimer()
    }
    
    func setupSchedule(bedtime: Date, waketime: Date) {
        // Save the schedule but don't set up DeviceActivity monitoring
        // The shields will be applied/cleared based on evaluateCurrentState()
        Logger.shared.log("✅ Schedule saved - shields will be applied based on current time evaluation")
        
        // Immediately evaluate and apply shields if we're currently in bedtime
        evaluateCurrentState()
    }
    
    private func startScheduleTimer() {
        // Check every minute for bedtime changes
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.evaluateCurrentState()
            }
        }
        Logger.shared.log("Started schedule timer for periodic bedtime evaluation")
    }
    
    deinit {
        scheduleTimer?.invalidate()
    }
    
    func evaluateCurrentState() {
        // Get actual user preferences instead of hardcoded times
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let bedtimeData = userDefaults?.data(forKey: "userBedtime")
        let waketimeData = userDefaults?.data(forKey: "userWaketime")
        
        let calendar = Calendar.current
        let now = Date()
        
        // Load actual bedtime/waketime or use defaults
        let bedtime: Date
        let waketime: Date
        
        if let bedtimeData = bedtimeData,
           let waketimeData = waketimeData,
           let savedBedtime = try? JSONDecoder().decode(Date.self, from: bedtimeData),
           let savedWaketime = try? JSONDecoder().decode(Date.self, from: waketimeData) {
            bedtime = savedBedtime
            waketime = savedWaketime
        } else {
            // Default schedule: 22:00 to 07:00
            bedtime = calendar.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
            waketime = calendar.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        }
        
        // Properly check if we're in bedtime window (handles midnight crossover)
        isInBedtime = isCurrentlyInBedtimeWindow(now: now, bedtime: bedtime, waketime: waketime)
        
        // Check if day is unlocked from UserDefaults/App Group
        isDayUnlocked = checkDayUnlockStatus()
        
        // Only apply shields if we have authorization and a valid selection
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            Logger.shared.log("Screen Time not authorized, cannot apply shields")
            return
        }
        
        // Apply or clear shields based on state
        if isInBedtime && !isDayUnlocked {
            Logger.shared.log("🌙 Bedtime active and not unlocked - applying shields")
            applyShields()
        } else {
            Logger.shared.log("☀️ Not bedtime or day unlocked - clearing shields (bedtime: \(isInBedtime), unlocked: \(isDayUnlocked))")
            clearShields()
        }
    }
    
    func applyShields(for selection: FamilyActivitySelection? = nil) {
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            Logger.shared.log("Cannot apply shields: Screen Time not authorized")
            return
        }
        
        guard let selection = selection ?? loadSavedSelection() else {
            Logger.shared.log("Cannot apply shields: No app selection found")
            return
        }
        
        // Ensure we have something to shield
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            Logger.shared.log("Cannot apply shields: No apps/categories/domains selected")
            return
        }
        
        // Apply shields with error handling and custom configuration
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            Logger.shared.log("Applied shields to \(selection.applicationTokens.count) applications")
        }
        
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            Logger.shared.log("Applied shields to \(selection.categoryTokens.count) categories")
        }
        
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
            Logger.shared.log("Applied shields to \(selection.webDomainTokens.count) web domains")
        }
        
        Logger.shared.log("🎨 Custom shield configuration should now be active via SunbreakMonitor extension")
        
        // Save shield application time for debugging
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(Date(), forKey: "lastShieldApplication")
    }
    
    func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    func unlockForToday() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let today = Calendar.current.startOfDay(for: Date())
        userDefaults?.set(today, forKey: "dayUnlockedFor")
        isDayUnlocked = true
        clearShields()
    }
    
    private func checkDayUnlockStatus() -> Bool {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        guard let unlockedDate = userDefaults?.object(forKey: "dayUnlockedFor") as? Date else {
            return false
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.isDate(unlockedDate, inSameDayAs: today)
    }
    
    private func loadSavedSelection() -> FamilyActivitySelection? {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        guard let data = userDefaults?.data(forKey: "savedSelection") else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
    
    func saveSelection(_ selection: FamilyActivitySelection) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        if let data = try? JSONEncoder().encode(selection) {
            userDefaults?.set(data, forKey: "savedSelection")
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentlyInBedtimeWindow(now: Date, bedtime: Date, waketime: Date) -> Bool {
        // Use centralized timezone handling
        return TimezoneHelper.shared.isCurrentlyInBedtimeWindow(
            bedtime: bedtime, 
            waketime: waketime, 
            now: now
        )
    }
    
    func saveSchedule(bedtime: Date, waketime: Date) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        
        // Save schedule to app group for extension access
        if let bedtimeData = try? JSONEncoder().encode(bedtime),
           let waketimeData = try? JSONEncoder().encode(waketime) {
            userDefaults?.set(bedtimeData, forKey: "userBedtime")
            userDefaults?.set(waketimeData, forKey: "userWaketime")
        }
        
        // Save timezone info for proper schedule evaluation
        let timeZone = Calendar.current.timeZone
        userDefaults?.set(timeZone.identifier, forKey: "savedTimeZone")
        
        // Re-evaluate current state with new schedule
        evaluateCurrentState()
    }
    
    // Add timezone change detection
    func handleTimezoneChange() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        let currentTimeZone = Calendar.current.timeZone.identifier
        let savedTimeZone = userDefaults?.string(forKey: "savedTimeZone")
        
        if savedTimeZone != currentTimeZone {
            Logger.shared.log("[ScheduleManager] Timezone changed from \(savedTimeZone ?? "unknown") to \(currentTimeZone)")
            
            // Update saved timezone
            userDefaults?.set(currentTimeZone, forKey: "savedTimeZone")
            
            // Clear any timezone-dependent cached data
            userDefaults?.removeObject(forKey: "dayUnlockedFor") // Reset day unlock status
            isDayUnlocked = false
            
            // Re-evaluate schedule with new timezone
            evaluateCurrentState()
            
            // Reset DeviceActivity monitoring with corrected schedule
            if let bedtimeData = userDefaults?.data(forKey: "userBedtime"),
               let waketimeData = userDefaults?.data(forKey: "userWaketime"),
               let bedtime = try? JSONDecoder().decode(Date.self, from: bedtimeData),
               let waketime = try? JSONDecoder().decode(Date.self, from: waketimeData) {
                setupSchedule(bedtime: bedtime, waketime: waketime)
            }
            
            // Notify other services about timezone change
            NotificationCenter.default.post(name: .timezoneChanged, object: nil)
        }
    }
}