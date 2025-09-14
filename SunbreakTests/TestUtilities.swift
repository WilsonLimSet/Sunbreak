import XCTest
import SwiftUI
import SwiftData
import FamilyControls
import StoreKit
@testable import Sunbreak

// MARK: - Test Data Factories

class TestDataFactory {
    
    // MARK: - User Preferences
    
    static func createUserPreferences(
        bedtime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!,
        wakeBufferMinutes: Int = 30,
        hasCompletedOnboarding: Bool = true
    ) -> UserPreferences {
        return UserPreferences(
            bedtime: bedtime,
            wakeBufferMinutes: wakeBufferMinutes,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
    }
    
    // MARK: - Selection Records
    
    static func createSelectionRecord(
        withApps appCount: Int = 3,
        withCategories categoryCount: Int = 1
    ) -> SelectionRecord {
        let selection = createFamilyActivitySelection(
            appCount: appCount,
            categoryCount: categoryCount
        )
        return SelectionRecord(selection: selection)
    }
    
    static func createFamilyActivitySelection(
        appCount: Int = 3,
        categoryCount: Int = 1
    ) -> FamilyActivitySelection {
        // Note: In real tests, you'd need actual tokens from the system
        // This creates an empty selection for testing structure
        return FamilyActivitySelection()
    }
    
    // MARK: - Entitlement State
    
    static func createEntitlementState(
        isAuthorized: Bool = true,
        type: String = "approved"
    ) -> EntitlementState {
        return EntitlementState(
            isAuthorized: isAuthorized,
            authorizationType: type
        )
    }
    
    // MARK: - Unlock State
    
    static func createUnlockState(
        unlockedForToday: Bool = false
    ) -> UnlockState {
        let state = UnlockState()
        if unlockedForToday {
            state.unlockForToday()
        }
        return state
    }
    
    
    // MARK: - Test Images
    
    static func createTestImage(
        width: Int = 100,
        height: Int = 100,
        color: UIColor = .blue
    ) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        color.setFill()
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
}

// MARK: - Test Helpers

class TestHelpers {
    
    // MARK: - Date Helpers
    
    static func dateFromComponents(hour: Int, minute: Int = 0, day: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
    }
    
    static func addDays(_ days: Int, to date: Date = Date()) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    static func startOfDay(_ date: Date = Date()) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    // MARK: - UserDefaults Helpers
    
    static func clearAppGroupDefaults() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.removePersistentDomain(forName: "group.com.sunbreak.shared")
    }
    
    static func setUnlockDate(_ date: Date) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(date, forKey: "dayUnlockedFor")
    }
    
    static func setSunriseDate(_ date: Date) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(date, forKey: "sunrise")
    }
    
    // MARK: - SwiftData Helpers
    
    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            UserPreferences.self,
            SelectionRecord.self,
            EntitlementState.self,
            UnlockState.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    static func createTestContext() throws -> ModelContext {
        let container = try createInMemoryContainer()
        return ModelContext(container)
    }
    
    // MARK: - Time Manipulation
    
    static func simulateTimeOfDay(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now
        ) ?? now
    }
    
    static func isBedtimeWindow(
        current: Date,
        bedtime: Date,
        waketime: Date
    ) -> Bool {
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
    
    // MARK: - Assertion Helpers
    
    static func assertDateEqual(
        _ date1: Date,
        _ date2: Date,
        accuracy: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            date1.timeIntervalSince1970,
            date2.timeIntervalSince1970,
            accuracy: accuracy,
            file: file,
            line: line
        )
    }
    
    static func assertSameDay(
        _ date1: Date,
        _ date2: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let calendar = Calendar.current
        XCTAssertTrue(
            calendar.isDate(date1, inSameDayAs: date2),
            "Dates should be on the same day: \(date1) vs \(date2)",
            file: file,
            line: line
        )
    }
}

// MARK: - Mock Objects


// MARK: - Mock Screen Time Auth Manager

class MockScreenTimeAuthManager: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var showAuthorizationError: Bool = false
    @Published var errorMessage: String = ""
    
    private var shouldAuthorize: Bool = true
    
    func setMockAuthorizationResult(_ authorized: Bool) {
        shouldAuthorize = authorized
    }
    
    func checkAuthorization() async {
        isAuthorized = shouldAuthorize
        authorizationStatus = shouldAuthorize ? .approved : .denied
    }
    
    func requestAuthorization() async {
        await checkAuthorization()
        
        if !isAuthorized {
            errorMessage = "Mock authorization denied"
            showAuthorizationError = true
        }
    }
}


// MARK: - Test Extensions

extension XCTestCase {
    
    /// Wait for a condition to be true with timeout
    func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        pollInterval: TimeInterval = 0.1
    ) async throws {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Condition not met within timeout of \(timeout) seconds")
                return
            }
            
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }
    
    /// Wait for an async operation to complete
    func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
}

struct TimeoutError: Error {}

// MARK: - Test Configuration

struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 5.0
    static let longTimeout: TimeInterval = 10.0
    static let shortTimeout: TimeInterval = 1.0
    
    static let sampleBedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 30))!
    static let sampleWaketime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    
    static let testAppGroup = "group.com.sunbreak.shared"
}