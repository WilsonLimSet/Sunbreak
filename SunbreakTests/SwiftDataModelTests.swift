import XCTest
import SwiftData
import FamilyControls
@testable import Sunbreak

final class SwiftDataModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        super.setUp()
        
        let schema = Schema([
            UserPreferences.self,
            SelectionRecord.self,
            EntitlementState.self,
            UnlockState.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            throw error
        }
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - UserPreferences Tests
    
    func testUserPreferencesCreation() throws {
        let calendar = Calendar.current
        let bedtime = calendar.date(from: DateComponents(hour: 22, minute: 30))!

        let preferences = UserPreferences(
            bedtime: bedtime,
            wakeBufferMinutes: 30,
            hasCompletedOnboarding: true
        )
        
        modelContext.insert(preferences)
        
        XCTAssertEqual(preferences.bedtime, bedtime)
        XCTAssertEqual(preferences.wakeBufferMinutes, 30)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertNotNil(preferences.createdAt)
        XCTAssertNotNil(preferences.updatedAt)
    }
    
    func testUserPreferencesDefaults() throws {
        let preferences = UserPreferences()
        
        XCTAssertNotNil(preferences.bedtime)
        XCTAssertEqual(preferences.wakeBufferMinutes, 30)
        XCTAssertFalse(preferences.hasCompletedOnboarding)
    }
    
    func testUserPreferencesUpdate() throws {
        let preferences = UserPreferences()
        let originalUpdatedAt = preferences.updatedAt
        
        let calendar = Calendar.current
        let newBedtime = calendar.date(from: DateComponents(hour: 23, minute: 0))!

        // Wait a moment to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        preferences.updateBedtime(newBedtime)

        XCTAssertEqual(preferences.bedtime, newBedtime)
        XCTAssertGreaterThan(preferences.updatedAt, originalUpdatedAt)
    }
    
    func testUserPreferencesPersistence() throws {
        let preferences = UserPreferences(hasCompletedOnboarding: true)
        modelContext.insert(preferences)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save preferences: \(error)")
        }
        
        // Verify it was saved
        let descriptor = FetchDescriptor<UserPreferences>()
        let fetchedPreferences = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedPreferences.count, 1)
        XCTAssertTrue(fetchedPreferences.first?.hasCompletedOnboarding ?? false)
    }
    
    // MARK: - SelectionRecord Tests
    
    func testSelectionRecordCreation() throws {
        let selection = FamilyActivitySelection()
        let record = SelectionRecord(selection: selection)
        
        modelContext.insert(record)
        
        XCTAssertNotNil(record.selectionData)
        XCTAssertNotNil(record.createdAt)
        XCTAssertNotNil(record.updatedAt)
    }
    
    func testSelectionRecordSerialization() throws {
        let selection = FamilyActivitySelection()
        let record = SelectionRecord(selection: selection)
        
        // Test that we can set and get the selection
        record.familyActivitySelection = selection
        let retrievedSelection = record.familyActivitySelection
        
        XCTAssertNotNil(retrievedSelection)
    }
    
    func testSelectionRecordUpdate() throws {
        let record = SelectionRecord()
        let originalUpdatedAt = record.updatedAt
        
        // Wait a moment to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)
        
        let newSelection = FamilyActivitySelection()
        record.familyActivitySelection = newSelection
        
        XCTAssertGreaterThan(record.updatedAt, originalUpdatedAt)
    }
    
    // MARK: - EntitlementState Tests
    
    func testEntitlementStateCreation() throws {
        let entitlementState = EntitlementState(
            isAuthorized: true,
            authorizationType: "approved"
        )
        
        modelContext.insert(entitlementState)
        
        XCTAssertTrue(entitlementState.isAuthorized)
        XCTAssertEqual(entitlementState.authorizationType, "approved")
        XCTAssertNotNil(entitlementState.lastChecked)
    }
    
    func testEntitlementStateDefaults() throws {
        let entitlementState = EntitlementState()
        
        XCTAssertFalse(entitlementState.isAuthorized)
        XCTAssertEqual(entitlementState.authorizationType, "notDetermined")
    }
    
    func testEntitlementStateUpdate() throws {
        let entitlementState = EntitlementState()
        let originalCheckedAt = entitlementState.lastChecked
        
        // Wait a moment to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)
        
        entitlementState.updateAuthorization(isAuthorized: true, type: "approved")
        
        XCTAssertTrue(entitlementState.isAuthorized)
        XCTAssertEqual(entitlementState.authorizationType, "approved")
        XCTAssertGreaterThan(entitlementState.lastChecked, originalCheckedAt)
    }
    
    // MARK: - UnlockState Tests
    
    func testUnlockStateCreation() throws {
        let unlockState = UnlockState()
        
        modelContext.insert(unlockState)
        
        XCTAssertNil(unlockState.dayUnlockedFor)
        XCTAssertNil(unlockState.lastSuccessAt)
        XCTAssertFalse(unlockState.isCurrentlyUnlocked)
    }
    
    func testUnlockStateUnlockForToday() throws {
        let unlockState = UnlockState()
        
        unlockState.unlockForToday()
        
        XCTAssertNotNil(unlockState.dayUnlockedFor)
        XCTAssertNotNil(unlockState.lastSuccessAt)
        XCTAssertTrue(unlockState.isCurrentlyUnlocked)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        XCTAssertTrue(calendar.isDate(unlockState.dayUnlockedFor!, inSameDayAs: today))
    }
    
    func testUnlockStateValidation() throws {
        let unlockState = UnlockState()
        let calendar = Calendar.current
        
        // Test with today's date
        unlockState.dayUnlockedFor = calendar.startOfDay(for: Date())
        XCTAssertTrue(unlockState.checkIfStillUnlocked())
        
        // Test with yesterday's date
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        unlockState.dayUnlockedFor = calendar.startOfDay(for: yesterday)
        XCTAssertFalse(unlockState.checkIfStillUnlocked())
        
        // Test with nil date
        unlockState.dayUnlockedFor = nil
        XCTAssertFalse(unlockState.checkIfStillUnlocked())
    }
    
    func testUnlockStateReset() throws {
        let unlockState = UnlockState()
        
        // First unlock
        unlockState.unlockForToday()
        XCTAssertTrue(unlockState.isCurrentlyUnlocked)
        XCTAssertNotNil(unlockState.dayUnlockedFor)
        
        // Then reset
        unlockState.resetUnlock()
        XCTAssertFalse(unlockState.isCurrentlyUnlocked)
        XCTAssertNil(unlockState.dayUnlockedFor)
    }
    
    // MARK: - Integration Tests
    
    func testModelPersistenceIntegration() throws {
        // Create all models
        let preferences = UserPreferences(hasCompletedOnboarding: true)
        let selectionRecord = SelectionRecord()
        let entitlementState = EntitlementState(isAuthorized: true, authorizationType: "approved")
        let unlockState = UnlockState()
        
        // Insert all models
        modelContext.insert(preferences)
        modelContext.insert(selectionRecord)
        modelContext.insert(entitlementState)
        modelContext.insert(unlockState)
        
        // Save
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save models: \(error)")
        }
        
        // Fetch and verify
        let prefsDescriptor = FetchDescriptor<UserPreferences>()
        let fetchedPrefs = try modelContext.fetch(prefsDescriptor)
        XCTAssertEqual(fetchedPrefs.count, 1)
        
        let selectionDescriptor = FetchDescriptor<SelectionRecord>()
        let fetchedSelections = try modelContext.fetch(selectionDescriptor)
        XCTAssertEqual(fetchedSelections.count, 1)
        
        let entitlementDescriptor = FetchDescriptor<EntitlementState>()
        let fetchedEntitlements = try modelContext.fetch(entitlementDescriptor)
        XCTAssertEqual(fetchedEntitlements.count, 1)
        
        let unlockDescriptor = FetchDescriptor<UnlockState>()
        let fetchedUnlocks = try modelContext.fetch(unlockDescriptor)
        XCTAssertEqual(fetchedUnlocks.count, 1)
    }
    
    func testModelRelationships() throws {
        // Test that models can coexist and be queried together
        let bedtime1 = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
        let bedtime2 = Calendar.current.date(from: DateComponents(hour: 23, minute: 0))!

        let preferences1 = UserPreferences(bedtime: bedtime1)
        let preferences2 = UserPreferences(bedtime: bedtime2)

        modelContext.insert(preferences1)
        modelContext.insert(preferences2)

        try modelContext.save()

        let descriptor = FetchDescriptor<UserPreferences>()
        let allPreferences = try modelContext.fetch(descriptor)

        XCTAssertEqual(allPreferences.count, 2)

        let bedtimes = allPreferences.map { Calendar.current.component(.hour, from: $0.bedtime) }.sorted()
        XCTAssertEqual(bedtimes, [22, 23])
    }
}