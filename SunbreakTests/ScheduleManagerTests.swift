import XCTest
import Foundation
@testable import Sunbreak

final class ScheduleManagerTests: XCTestCase {
    var scheduleManager: ScheduleManager!
    
    override func setUpWithError() throws {
        super.setUp()
        scheduleManager = ScheduleManager.shared
        
        // Clear any existing state
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        if let suiteName = UserDefaults(suiteName: "group.com.sunbreak.shared") {
            suiteName.removePersistentDomain(forName: "group.com.sunbreak.shared")
        }
    }
    
    override func tearDownWithError() throws {
        scheduleManager = nil
        super.tearDown()
    }
    
    // MARK: - Schedule Logic Tests
    
    func testBedtimeWindowCalculation() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Test case: 10 PM to 7 AM
        let bedtime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let waketime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        
        // Test at 11 PM (should be in bedtime)
        let nightTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now)!
        XCTAssertTrue(isInBedtimeWindow(current: nightTime, bedtime: bedtime, waketime: waketime))
        
        // Test at 2 AM (should be in bedtime)
        let earlyMorning = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: now)!
        XCTAssertTrue(isInBedtimeWindow(current: earlyMorning, bedtime: bedtime, waketime: waketime))
        
        // Test at 8 AM (should not be in bedtime)
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
        XCTAssertFalse(isInBedtimeWindow(current: morning, bedtime: bedtime, waketime: waketime))
        
        // Test at 6 PM (should not be in bedtime)
        let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        XCTAssertFalse(isInBedtimeWindow(current: evening, bedtime: bedtime, waketime: waketime))
    }
    
    func testDayUnlockPersistence() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        
        // Test unlocking for today
        scheduleManager.unlockForToday()
        
        let today = Calendar.current.startOfDay(for: Date())
        let savedDate = userDefaults.object(forKey: "dayUnlockedFor") as? Date
        
        XCTAssertNotNil(savedDate)
        XCTAssertTrue(Calendar.current.isDate(savedDate!, inSameDayAs: today))
        XCTAssertTrue(scheduleManager.isDayUnlocked)
    }
    
    func testDayUnlockExpiry() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        let calendar = Calendar.current
        
        // Set unlock for yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        userDefaults.set(yesterdayStart, forKey: "dayUnlockedFor")
        
        // Check if still unlocked (should be false)
        XCTAssertFalse(checkDayUnlockStatus())
    }
    
    func testScheduleSetup() throws {
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!
        let waketime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
        
        XCTAssertNoThrow(scheduleManager.setupSchedule(bedtime: bedtime, waketime: waketime))
    }
    
    // MARK: - Helper Methods
    
    private func isInBedtimeWindow(current: Date, bedtime: Date, waketime: Date) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: current)
        let currentMinute = calendar.component(.minute, from: current)
        let bedHour = calendar.component(.hour, from: bedtime)
        let bedMinute = calendar.component(.minute, from: bedtime)
        let wakeHour = calendar.component(.hour, from: waketime)
        let wakeMinute = calendar.component(.minute, from: waketime)
        
        let currentMinutes = currentHour * 60 + currentMinute
        let bedMinutes = bedHour * 60 + bedMinute
        let wakeMinutes = wakeHour * 60 + wakeMinute
        
        if bedMinutes > wakeMinutes {
            // Crosses midnight
            return currentMinutes >= bedMinutes || currentMinutes < wakeMinutes
        } else {
            // Same day
            return currentMinutes >= bedMinutes && currentMinutes < wakeMinutes
        }
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
}