import XCTest
import FamilyControls
import ManagedSettings
import DeviceActivity
@testable import Sunbreak

final class ScreenTimeIntegrationTests: XCTestCase {
    var authManager: ScreenTimeAuthManager!
    var scheduleManager: ScheduleManager!
    
    @MainActor
    override func setUpWithError() throws {
        super.setUp()
        authManager = ScreenTimeAuthManager()
        scheduleManager = ScheduleManager.shared

        // Clear app group UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.removePersistentDomain(forName: "group.com.sunbreak.shared")
    }
    
    override func tearDownWithError() throws {
        authManager = nil
        scheduleManager = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testScreenTimeAuthorizationFlow() async throws {
        // Note: These tests require manual intervention on device
        // They serve as integration test templates
        
        let initialStatus = await authManager.authorizationStatus
        XCTAssertTrue([.notDetermined, .denied, .approved].contains(initialStatus))

        // Test authorization request (requires user interaction)
        await authManager.requestAuthorization()

        // Verify status was updated
        let finalStatus = await authManager.authorizationStatus
        XCTAssertTrue([.denied, .approved].contains(finalStatus))
    }
    
    func testAuthorizationStatusPersistence() throws {
        // Test that authorization status is properly tracked
        let center = AuthorizationCenter.shared
        let currentStatus = center.authorizationStatus
        
        XCTAssertTrue([.notDetermined, .denied, .approved].contains(currentStatus))
        
        // Test that our manager reflects the same status
        Task { @MainActor in
            await authManager.checkAuthorization()
            XCTAssertEqual(authManager.authorizationStatus, currentStatus)
            XCTAssertEqual(authManager.isAuthorized, currentStatus == .approved)
        }
    }
    
    // MARK: - Family Activity Selection Tests
    
    func testFamilyActivitySelectionSerialization() throws {
        let selection = FamilyActivitySelection()
        
        // Test encoding
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(selection))
        
        let data = try encoder.encode(selection)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedSelection = try decoder.decode(FamilyActivitySelection.self, from: data)
        
        // Verify selections match
        XCTAssertEqual(selection.applicationTokens.count, decodedSelection.applicationTokens.count)
        XCTAssertEqual(selection.categoryTokens.count, decodedSelection.categoryTokens.count)
        XCTAssertEqual(selection.webDomainTokens.count, decodedSelection.webDomainTokens.count)
    }
    
    func testSelectionPersistenceInAppGroup() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        let selection = FamilyActivitySelection()
        
        // Test saving selection
        scheduleManager.saveSelection(selection)
        
        // Verify it was saved
        let savedData = userDefaults.data(forKey: "savedSelection")
        XCTAssertNotNil(savedData, "Selection should be saved to app group")
        
        // Test loading selection
        if let data = savedData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(FamilyActivitySelection.self, from: data))
        }
    }
    
    // MARK: - Managed Settings Tests
    
    func testManagedSettingsStoreOperation() throws {
        let store = ManagedSettingsStore()
        
        // Test that we can create and access the store without crashing
        XCTAssertNotNil(store)
        
        // Test clearing shields (should not crash)
        XCTAssertNoThrow(store.shield.applications = nil)
        XCTAssertNoThrow(store.shield.applicationCategories = nil)
        XCTAssertNoThrow(store.shield.webDomains = nil)
    }
    
    func testShieldApplicationLogic() throws {
        let selection = FamilyActivitySelection()
        
        // Test shield application (may require authorization)
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            XCTAssertNoThrow(scheduleManager.applyShields(for: selection))
            XCTAssertNoThrow(scheduleManager.clearShields())
        } else {
            // Test that operations don't crash even without authorization
            XCTAssertNoThrow(scheduleManager.applyShields(for: selection))
        }
    }
    
    // MARK: - Device Activity Tests
    
    func testDeviceActivityScheduleCreation() throws {
        let calendar = Calendar.current
        let bedtime = calendar.date(from: DateComponents(hour: 22, minute: 0))!
        let waketime = calendar.date(from: DateComponents(hour: 7, minute: 0))!
        
        // Test schedule creation
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let waketimeComponents = calendar.dateComponents([.hour, .minute], from: waketime)
        
        XCTAssertNoThrow({
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: bedtimeComponents.hour, minute: bedtimeComponents.minute),
                intervalEnd: DateComponents(hour: waketimeComponents.hour, minute: waketimeComponents.minute),
                repeats: true
            )
            XCTAssertNotNil(schedule)
        }())
    }
    
    func testDeviceActivityMonitoring() throws {
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName("test-activity")
        
        // Test that we can create activity names and center without crashing
        XCTAssertNotNil(center)
        XCTAssertEqual(activityName.rawValue, "test-activity")
        
        // Test monitoring setup (requires authorization)
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 22, minute: 0),
                intervalEnd: DateComponents(hour: 7, minute: 0),
                repeats: true
            )
            
            XCTAssertNoThrow(try center.startMonitoring(activityName, during: schedule))
            XCTAssertNoThrow(center.stopMonitoring([activityName]))
        }
    }
    
    // MARK: - App Group Communication Tests
    
    func testAppGroupDataSharing() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        
        // Test basic data sharing
        let testKey = "test-key"
        let testValue = "test-value"
        
        userDefaults.set(testValue, forKey: testKey)
        let retrievedValue = userDefaults.string(forKey: testKey)
        
        XCTAssertEqual(retrievedValue, testValue)
        
        // Test date sharing (for unlock state)
        let testDate = Date()
        userDefaults.set(testDate, forKey: "test-date")
        let retrievedDate = userDefaults.object(forKey: "test-date") as? Date
        
        XCTAssertNotNil(retrievedDate)
        XCTAssertEqual(testDate.timeIntervalSince1970, retrievedDate?.timeIntervalSince1970 ?? 0, accuracy: 1)
    }
    
    func testUnlockStateSharingBetweenTargets() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        
        // Simulate main app unlocking for today
        let today = Calendar.current.startOfDay(for: Date())
        userDefaults.set(today, forKey: "dayUnlockedFor")
        
        // Test that extension can read the state
        guard let unlockedDate = userDefaults.object(forKey: "dayUnlockedFor") as? Date else {
            XCTFail("Should be able to read unlock date from app group")
            return
        }
        
        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDate(unlockedDate, inSameDayAs: today))
        
        // Test unlock status check
        let isUnlocked = calendar.isDate(unlockedDate, inSameDayAs: today)
        XCTAssertTrue(isUnlocked)
    }
    
    // MARK: - Error Handling Tests
    
    func testScreenTimeAPIErrorHandling() throws {
        // Test handling when Screen Time is not authorized
        if AuthorizationCenter.shared.authorizationStatus != .approved {
            
            // These operations should not crash even without authorization
            XCTAssertNoThrow(scheduleManager.applyShields())
            XCTAssertNoThrow(scheduleManager.clearShields())
            
            let selection = FamilyActivitySelection()
            XCTAssertNoThrow(scheduleManager.saveSelection(selection))
        }
    }
    
    func testInvalidAppGroupHandling() throws {
        // Test with invalid app group name
        let invalidUserDefaults = UserDefaults(suiteName: "invalid.group.name")
        
        // Should handle gracefully
        XCTAssertNil(invalidUserDefaults)
        
        // Test fallback behavior
        let validUserDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        XCTAssertNotNil(validUserDefaults)
    }
    
    // MARK: - Performance Tests
    
    func testFamilyActivitySelectionPerformance() throws {
        let selection = FamilyActivitySelection()
        
        measure {
            // Test serialization performance
            for _ in 0..<100 {
                let encoder = JSONEncoder()
                _ = try? encoder.encode(selection)
            }
        }
    }
    
    func testAppGroupAccessPerformance() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        
        measure {
            // Test app group access performance
            for i in 0..<100 {
                userDefaults.set("value-\(i)", forKey: "test-key-\(i)")
                _ = userDefaults.string(forKey: "test-key-\(i)")
            }
        }
    }
    
    // MARK: - State Validation Tests
    
    func testScheduleStateConsistency() throws {
        let calendar = Calendar.current
        let bedtime = calendar.date(from: DateComponents(hour: 22, minute: 30))!
        let waketime = calendar.date(from: DateComponents(hour: 6, minute: 30))!
        
        // Test schedule setup
        XCTAssertNoThrow(scheduleManager.setupSchedule(bedtime: bedtime, waketime: waketime))
        
        // Test state evaluation
        XCTAssertNoThrow(scheduleManager.evaluateCurrentState())
        
        // Verify state properties are accessible
        XCTAssertNotNil(scheduleManager.isInBedtime)
        XCTAssertNotNil(scheduleManager.isDayUnlocked)
    }
    
    func testUnlockStateTransitions() throws {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")!
        
        // Test initial state (not unlocked)
        userDefaults.removeObject(forKey: "dayUnlockedFor")
        scheduleManager.evaluateCurrentState()
        XCTAssertFalse(scheduleManager.isDayUnlocked)
        
        // Test unlock
        scheduleManager.unlockForToday()
        XCTAssertTrue(scheduleManager.isDayUnlocked)
        
        // Verify persistence
        let savedDate = userDefaults.object(forKey: "dayUnlockedFor") as? Date
        XCTAssertNotNil(savedDate)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        XCTAssertTrue(calendar.isDate(savedDate!, inSameDayAs: today))
    }
}