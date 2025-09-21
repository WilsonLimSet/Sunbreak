import SwiftUI
import FamilyControls
import CoreLocation
import SwiftData

struct OnboardingView: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var selection = FamilyActivitySelection()
    @State private var bedtime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var wakeBufferMinutes: Int = 30
    @State private var locationManager = LocationManager()
    @State private var showingPermissions = false
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            // Consistent black background like the rest of the app
            Color.black
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator - properly positioned below safe area
                HStack(spacing: 4) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(index <= currentStep ? Color("BrandOrange") : Color.white.opacity(0.3))
                            .frame(height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.clear)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    LocationStep(locationManager: locationManager)
                        .tag(1)
                    
                    ScheduleStep(bedtime: $bedtime, wakeBufferMinutes: $wakeBufferMinutes)
                        .tag(2)
                    
                    ScreenTimeAuthStep()
                        .tag(3)
                    
                    AppSelectionStep(selection: $selection)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons - better positioned
                VStack(spacing: 0) {
                    // Main continue button
                    Button(action: {
                        if currentStep == totalSteps - 1 {
                            completeOnboarding()
                        } else {
                            // Check if we can proceed to next step
                            if canProceedToNextStep() {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                                .font(.system(size: 18, weight: .bold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canProceedToNextStep() || currentStep == totalSteps - 1 ? Color("BrandOrange") : Color.gray)
                                .shadow(color: (canProceedToNextStep() || currentStep == totalSteps - 1 ? Color("BrandOrange") : Color.gray).opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Back button (if not first step)
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep -= 1
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
    
    private func canProceedToNextStep() -> Bool {
        switch currentStep {
        case 1: // Location step - Allow skipping
            return true // Users can skip location permission
        case 3: // Screen Time step
            return authManager.isAuthorized
        case 4: // App Selection step
            return !selection.applicationTokens.isEmpty
        default:
            return true
        }
    }
    
    private func completeOnboarding() {
        Logger.shared.logOnboarding("Starting completion process...")
        
        do {
            // Check if preferences already exist
            let descriptor = FetchDescriptor<UserPreferences>()
            let existingPreferences = try modelContext.fetch(descriptor)
            
            let preferences: UserPreferences
            if let existing = existingPreferences.first {
                // Update existing preferences
                existing.updateBedtime(bedtime)
                existing.updateWakeBuffer(wakeBufferMinutes)
                existing.hasCompletedOnboarding = true
                existing.updatedAt = Date()
                preferences = existing
                Logger.shared.logOnboarding("Updated existing preferences")
            } else {
                // Create new preferences
                preferences = UserPreferences(
                    bedtime: bedtime,
                    wakeBufferMinutes: wakeBufferMinutes,
                    hasCompletedOnboarding: true
                )
                modelContext.insert(preferences)
                Logger.shared.logOnboarding("Created new preferences")
            }
            
            // Handle selection record
            let selectionDescriptor = FetchDescriptor<SelectionRecord>()
            let existingSelections = try modelContext.fetch(selectionDescriptor)
            
            if let existingSelection = existingSelections.first {
                // Update existing selection
                existingSelection.familyActivitySelection = selection
                Logger.shared.logOnboarding("Updated existing selection")
            } else {
                // Create new selection
                let selectionRecord = SelectionRecord(selection: selection)
                modelContext.insert(selectionRecord)
                Logger.shared.logOnboarding("Created new selection")
            }
            
            // Save to SwiftData
            try modelContext.save()
            Logger.shared.logOnboarding("SwiftData saved successfully")
            
            // Save to UserDefaults for immediate access
            ScheduleManager.shared.saveSelection(selection)
            // Use sunrise as wake time
            let sunrise = getSunriseTime()
            ScheduleManager.shared.saveSchedule(bedtime: bedtime, waketime: sunrise)
            ScheduleManager.shared.setupSchedule(bedtime: bedtime, waketime: sunrise)
            
            Logger.shared.logOnboarding("Onboarding completed successfully")
            
            // No trial needed - app is completely free
            
        } catch {
            Logger.shared.logError("Failed to complete onboarding", error: error)
            
            // Fallback: still try to save to UserDefaults
            ScheduleManager.shared.saveSelection(selection)
            let sunrise = getSunriseTime()
            ScheduleManager.shared.saveSchedule(bedtime: bedtime, waketime: sunrise)
        }
    }
    
    private func getSunriseTime() -> Date {
        // Try to get sunrise from LocationManager
        if let sunrise = locationManager.sunrise {
            return sunrise
        }
        
        // Fallback to UserDefaults (saved by LocationManager)
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        if let sunrise = userDefaults?.object(forKey: "sunrise") as? Date {
            return sunrise
        }
        
        // Final fallback to 7 AM
        return Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    }
}

struct WelcomeStep: View {
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)

            // Transparent logo - positioned lower
            Image("Transparent")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100, maxHeight: 100)
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateElements)
                .accessibilityLabel("SunBreak logo")

            Spacer(minLength: 40)
            
            VStack(spacing: 20) {
                Text("Welcome to SunBreak")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                
                Text("Sleep well, live intentionally")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("BrandOrange"))
                    .multilineTextAlignment(.center)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                
                VStack(spacing: 16) {
                    BenefitRow(
                        icon: "moon.zzz.fill",
                        text: "Block distracting apps at bedtime",
                        delay: 0.6
                    )
                    
                    BenefitRow(
                        icon: "sun.max.fill",
                        text: "Wake up feeling refreshed",
                        delay: 0.8
                    )
                    
                    BenefitRow(
                        icon: "heart.fill",
                        text: "Build lasting healthy habits",
                        delay: 1.0
                    )
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 32)
            
            Spacer(minLength: 40)
            
            // Free badge - more prominent
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color("BrandOrange"))
                        .font(.title3)
                    Text("Always Free")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("BrandOrange"))
                }
                
                Text("No subscriptions • No hidden fees")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color("BrandOrange").opacity(0.15), Color("BrandOrange").opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("BrandOrange").opacity(0.4), lineWidth: 1.5)
                    )
            )
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
            
            Spacer(minLength: 60)
        }
        .onAppear {
            animateElements = true
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color("BrandOrange"))
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : -20)
        .animation(.easeOut(duration: 0.5).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

struct ScreenTimeAuthStep: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    @State private var isRequesting = false
    @State private var showSettingsAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hourglass.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(Color("BrandOrange"))
            
            Text("Screen Time Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("SunBreak needs Screen Time access to manage your selected apps during bedtime hours.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
            
            if authManager.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Screen Time access granted")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: {
                    isRequesting = true
                    Task {
                        await authManager.requestAuthorization()
                        isRequesting = false
                        
                        // If still not authorized after request, show settings option
                        if !authManager.isAuthorized && authManager.authorizationStatus == .denied {
                            showSettingsAlert = true
                        }
                    }
                }) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Grant Access")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color("BrandOrange"))
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isRequesting)
            }
            
            Spacer()
        }
        .padding()
        .alert("Screen Time Access Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable Screen Time access in Settings to continue.")
        }
        .alert("Authorization Error", isPresented: $authManager.showAuthorizationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authManager.errorMessage)
        }
    }
}

struct AppSelectionStep: View {
    @Binding var selection: FamilyActivitySelection
    @State private var showingPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 80))
                .foregroundColor(Color("BrandOrange"))
            
            Text("Choose Apps to Limit")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select the apps you want to restrict during bedtime. You can always change this later.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingPicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(selection.applicationTokens.isEmpty ? "Select Apps" : "Apps Selected: \(selection.applicationTokens.count)")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("BrandOrange"))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            
            Spacer()
        }
        .padding()
    }
}

struct ScheduleStep: View {
    @Binding var bedtime: Date
    @Binding var wakeBufferMinutes: Int
    @State private var animateElements = false
    
    private var schedulePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let bedtimeStr = formatter.string(from: bedtime)
        
        if wakeBufferMinutes == 0 {
            return "Bedtime: \(bedtimeStr) • Wake: Sunrise"
        } else {
            let bufferStr = formatBufferTime(wakeBufferMinutes)
            return "Bedtime: \(bedtimeStr) • Wake: Sunrise + \(bufferStr)"
        }
    }
    
    private func formatBufferTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color("BrandOrange"))
                        .scaleEffect(animateElements ? 1.0 : 0.8)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateElements)
                    
                    VStack(spacing: 8) {
                        Text("Set Your Sleep Schedule")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                        
                        Text("Block distracting apps during bedtime hours")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                }
                .padding(.top, 40)
                
                // Main schedule card
                VStack(spacing: 20) {
                    // Bedtime picker
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                                .foregroundColor(Color("BrandOrange"))
                            
                            Text("Bedtime")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .scaleEffect(1.1)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Wake buffer
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wake Time")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Sunrise + \(formatBufferTime(wakeBufferMinutes))")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("No buffer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("2 hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(wakeBufferMinutes) },
                                    set: { wakeBufferMinutes = Int($0) }
                                ),
                                in: 0...120,
                                step: 15
                            )
                            .tint(.orange)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
                )
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                
                // Bottom spacing for navigation
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateElements = true
        }
    }
}


struct LocationStep: View {
    @ObservedObject var locationManager: LocationManager
    @State private var showLocationDeniedAlert = false
    @State private var manualSunriseTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var showManualPicker = false

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "location.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("BrandOrange"))

            Text("Sunrise Time")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                Text("Allow location to automatically calculate sunrise, or set it manually.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if locationManager.authorizationStatus == .authorizedWhenInUse {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Using location-based sunrise")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                VStack(spacing: 20) {
                    // Location access button (if not denied)
                    if locationManager.authorizationStatus != .denied {
                        Button(action: {
                            locationManager.requestLocation()
                        }) {
                            Text("Use Location for Sunrise")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("BrandOrange"))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Manual sunrise picker
                    VStack(spacing: 12) {
                        Text("Set Sunrise Time Manually:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        DatePicker("", selection: $manualSunriseTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(height: 100)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .onChange(of: manualSunriseTime) { _, _ in
                                saveManualSunriseTime()
                            }

                        Text("Sunrise: \(manualSunriseTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Settings link for denied location
                    if locationManager.authorizationStatus == .denied {
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Enable Location in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .underline()
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            loadManualSunriseTime()
        }
    }

    private func saveManualSunriseTime() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(manualSunriseTime, forKey: "manualSunriseTime")
        userDefaults?.set(true, forKey: "useManualSunrise")
    }

    private func loadManualSunriseTime() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        if let savedTime = userDefaults?.object(forKey: "manualSunriseTime") as? Date {
            manualSunriseTime = savedTime
        }
    }
}


