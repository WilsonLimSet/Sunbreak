import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    
    // Optimized query with sorting and limit to get only the first (most recent) preference
    @Query(sort: \UserPreferences.updatedAt, order: .reverse, animation: .default) 
    private var preferences: [UserPreferences]
    
    @State private var selectedTab = 0
    @State private var isInitialized = false
    @State private var onboardingCompleted = false
    
    // Cache the first preference to avoid repeated array access
    private var currentPreference: UserPreferences? {
        preferences.first
    }
    
    var hasCompletedOnboarding: Bool {
        // Use cached state after first load to prevent loops
        if isInitialized {
            return onboardingCompleted
        }
        return currentPreference?.hasCompletedOnboarding ?? false
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .onDisappear {
                        // Mark onboarding as completed when view disappears
                        checkOnboardingStatus()
                    }
            } else if !authManager.isAuthorized {
                AuthorizationRequiredView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            initializeAppState()
        }
        .onChange(of: currentPreference?.hasCompletedOnboarding) { _, newValue in
            if let completed = newValue, completed != onboardingCompleted {
                Logger.shared.logOnboarding("Onboarding status changed: \(completed)")
                onboardingCompleted = completed
            }
        }
    }
    
    private func initializeAppState() {
        guard !isInitialized else { return }
        
        let completed = currentPreference?.hasCompletedOnboarding ?? false
        onboardingCompleted = completed
        isInitialized = true
        
        Logger.shared.logOnboarding("Initialized - onboarding completed: \(completed)")
    }
    
    private func checkOnboardingStatus() {
        // Double-check onboarding status from database
        if let prefs = currentPreference, prefs.hasCompletedOnboarding {
            onboardingCompleted = true
            Logger.shared.logOnboarding("Confirmed onboarding completion")
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @StateObject private var scheduleManager = ScheduleManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            AppsSelectionView()
                .tabItem {
                    Label("Apps", systemImage: "apps.iphone")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(Color("BrandOrange"))
    }
}

struct AuthorizationRequiredView: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("BrandOrange"))
            
            Text("Screen Time Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Sunbreak needs Screen Time access to help you manage your app usage during bedtime.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await authManager.requestAuthorization()
                }
            }) {
                Text("Grant Access")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandOrange"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}