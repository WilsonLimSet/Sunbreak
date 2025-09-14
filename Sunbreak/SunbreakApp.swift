import SwiftUI
import FamilyControls
import SwiftData

@main
struct SunbreakApp: App {
    @StateObject private var authManager = ScreenTimeAuthManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserPreferences.self,
            SelectionRecord.self,
            EntitlementState.self,
            UnlockState.self
        ])
        
        // iOS 17.0 compatible configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Logger.shared.log("SwiftData ModelContainer created successfully")
            return container
        } catch {
            // More graceful error handling for iOS 17.0
            Logger.shared.log("Failed to create ModelContainer: \(error)")
            
            // Check if it's a migration error and handle it
            if (error as NSError).code == 134110 { // Migration error code
                Logger.shared.log("Migration error detected, attempting to delete old store and recreate")
                
                // Get the default store URL
                let appGroupID = "group.com.sunbreak.app" // Update with your actual app group ID if different
                if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
                    let storeURL = containerURL.appendingPathComponent("Library/Application Support/default.store")
                    let shmURL = storeURL.appendingPathExtension("shm")
                    let walURL = storeURL.appendingPathExtension("wal")
                    
                    // Delete the old store files
                    try? FileManager.default.removeItem(at: storeURL)
                    try? FileManager.default.removeItem(at: shmURL)
                    try? FileManager.default.removeItem(at: walURL)
                    
                    Logger.shared.log("Deleted old store files, attempting to recreate container")
                }
            }
            
            // Try fallback with simpler configuration or fresh store
            do {
                let fallbackContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                Logger.shared.log("Using fallback ModelContainer after handling migration")
                return fallbackContainer
            } catch {
                // Last resort: crash with detailed error info
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onAppear {
                    Task {
                        await authManager.checkAuthorization()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await authManager.checkAuthorization()
                            ScheduleManager.shared.handleTimezoneChange()
                            ScheduleManager.shared.evaluateCurrentState()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}