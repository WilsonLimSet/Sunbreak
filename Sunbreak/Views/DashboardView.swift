import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var scheduleManager = ScheduleManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // Schedule editing states
    @State private var bedtime: Date = Date()
    @State private var wakeBufferMinutes: Int = 30
    @State private var hasChanges = false
    @State private var showingSaveConfirmation = false
    
    // Timer for live updates
    @State private var currentTime = Date()
    
    var currentPreferences: UserPreferences? {
        preferences.first
    }
    
    var isScheduleLocked: Bool {
        // Use SAVED bedtime (not the one being edited) to determine if we're locked
        let savedBedtime = currentPreferences?.bedtime ?? bedtime
        let savedWakeBuffer = currentPreferences?.wakeBufferMinutes ?? wakeBufferMinutes

        // Calculate wake time based on saved values
        let sunrise = locationManager.sunrise ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        let effectiveWakeTime = Calendar.current.date(byAdding: .minute, value: savedWakeBuffer, to: sunrise) ?? sunrise

        let currentlyInBedtime = TimezoneHelper.shared.isCurrentlyInBedtimeWindow(
            bedtime: savedBedtime,
            waketime: effectiveWakeTime
        )
        return currentlyInBedtime && !isDayUnlocked()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    StatusOverviewCard()
                    
                    // Schedule Lock Banner (if locked)
                    if isScheduleLocked {
                        ScheduleLockedBanner()
                    }
                    
                    // Schedule Configuration
                    ScheduleConfigurationCard()
                    
                    // Save Button (if changes and not locked)
                    if hasChanges && !isScheduleLocked {
                        SaveChangesButton()
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Dashboard")
            .onAppear {
                loadCurrentSchedule()
                startTimeTimer()
                locationManager.requestLocation()
            }
            .alert("Schedule Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your sleep schedule has been updated successfully.")
            }
        }
    }
    
    // MARK: - Status Overview Card
    @ViewBuilder
    private func StatusOverviewCard() -> some View {
        VStack(spacing: 20) {
            // Time until next transition
            TimeUntilTransitionView()
            
            // Current schedule info
            CurrentScheduleInfoView()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder 
    private func TimeUntilTransitionView() -> some View {
        VStack(spacing: 12) {
            if scheduleManager.isInBedtime {
                // During bedtime - show time until wake
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text("Sleep Mode Active")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(timeUntilWake())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("until apps unlock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // During day - show time until bedtime
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Day Mode")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(timeUntilBedtime())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("until bedtime")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func CurrentScheduleInfoView() -> some View {
        if let schedule = getCurrentSchedule() {
            VStack(spacing: 8) {
                HStack {
                    Text(currentDayType())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatTime(schedule.bedtime)) - \(formatTime(schedule.waketime))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Progress bar showing current time in the day cycle
                ScheduleProgressBar(bedtime: schedule.bedtime, waketime: schedule.waketime)
            }
        }
    }
    
    // MARK: - Schedule Locked Banner
    @ViewBuilder
    private func ScheduleLockedBanner() -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule Locked During Bedtime")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Changes blocked to maintain healthy sleep habits")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
            }
            
            Button("Time until unlock: \(timeUntilWake())") {
                // Could show unlock flow if needed
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.orange)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.white)
            .cornerRadius(20)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Schedule Configuration Card
    @ViewBuilder
    private func ScheduleConfigurationCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Main Schedule
            ScheduleSection(
                title: "Daily Schedule",
                bedtime: $bedtime,
                color: .orange,
                isLocked: isScheduleLocked
            )
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func ScheduleSection(title: String, bedtime: Binding<Date>, color: Color, isLocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "calendar")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            VStack(spacing: 12) {
                DatePicker("Bedtime", selection: bedtime, displayedComponents: .hourAndMinute)
                    .disabled(isLocked)
                    .onChange(of: bedtime.wrappedValue) { _, _ in
                        if !isLocked { hasChanges = true }
                    }
                
                // Show effective wake time (sunrise + buffer)
                if scheduleManager.isInBedtime {
                    HStack {
                        Text("Wake Time")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatEffectiveWakeTime())
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                
                // Buffer configuration (only show during day mode)
                if !scheduleManager.isInBedtime {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Buffer after sunrise:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatBufferTime())
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    
                    if !isLocked {
                        HStack {
                            Text("0 min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { Double(wakeBufferMinutes) },
                                    set: { newValue in
                                        wakeBufferMinutes = Int(newValue)
                                        hasChanges = true
                                    }
                                ),
                                in: 0...120,
                                step: 15
                            )
                            .tint(.orange)
                            
                            Text("2 hrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    }
                    .padding(.top, 4)
                }
                
                if locationManager.location == nil {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Enable location for accurate sunrise times")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if !scheduleManager.isInBedtime {
                    BedtimeSummary(bedtime: bedtime.wrappedValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatEffectiveWakeTime() -> String {
        let effectiveWakeTime = getEffectiveWakeTime()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let sunrise = getSunriseTime() {
            if wakeBufferMinutes == 0 {
                return "\(formatter.string(from: effectiveWakeTime)) (at sunrise)"
            } else {
                let sunriseStr = formatter.string(from: sunrise)
                return "\(formatter.string(from: effectiveWakeTime)) (sunrise at \(sunriseStr))"
            }
        } else {
            return formatter.string(from: effectiveWakeTime)
        }
    }
    
    private func formatBufferTime() -> String {
        if wakeBufferMinutes == 0 {
            return "None"
        } else if wakeBufferMinutes < 60 {
            return "\(wakeBufferMinutes) min"
        } else {
            let hours = wakeBufferMinutes / 60
            let minutes = wakeBufferMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
    
    @ViewBuilder
    private func SaveChangesButton() -> some View {
        Button(action: saveSchedule) {
            Label("Save Changes", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Functions
    
    private func timeUntilBedtime() -> String {
        guard let schedule = getCurrentSchedule() else { return "--:--" }
        return formatTimeInterval(until: schedule.bedtime, from: currentTime)
    }
    
    private func timeUntilWake() -> String {
        let effectiveWakeTime = getEffectiveWakeTime()
        return formatTimeInterval(until: effectiveWakeTime, from: currentTime)
    }
    
    private func getSunriseTime() -> Date? {
        // Try to get sunrise from LocationManager first
        if let sunrise = locationManager.sunrise {
            return sunrise
        }
        
        // Fallback to UserDefaults (saved by LocationManager)
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        return userDefaults?.object(forKey: "sunrise") as? Date
    }
    
    private func getEffectiveWakeTime() -> Date {
        // Get sunrise time
        guard let sunrise = getSunriseTime() else {
            // Fallback to 7 AM + buffer
            let defaultWake = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
            return Calendar.current.date(byAdding: .minute, value: wakeBufferMinutes, to: defaultWake) ?? defaultWake
        }
        
        // Add buffer to sunrise
        return Calendar.current.date(byAdding: .minute, value: wakeBufferMinutes, to: sunrise) ?? sunrise
    }
    
    private func formatTimeInterval(until targetTime: Date, from currentTime: Date) -> String {
        let calendar = Calendar.current
        let now = currentTime
        
        // Create target time for today
        let targetToday = calendar.date(
            bySettingHour: calendar.component(.hour, from: targetTime),
            minute: calendar.component(.minute, from: targetTime),
            second: 0,
            of: now
        ) ?? targetTime
        
        let actualTarget: Date
        
        // If target time has passed today, use tomorrow
        if targetToday <= now {
            actualTarget = calendar.date(byAdding: .day, value: 1, to: targetToday) ?? targetToday
        } else {
            actualTarget = targetToday
        }
        
        let timeInterval = actualTarget.timeIntervalSince(now)
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func startTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func getCurrentSchedule() -> (bedtime: Date, waketime: Date)? {
        let effectiveWakeTime = getEffectiveWakeTime()
        return (bedtime: bedtime, waketime: effectiveWakeTime)
    }
    
    private func currentDayType() -> String {
        return "Daily Schedule"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isDayUnlocked() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared"),
           let unlockedDate = userDefaults.object(forKey: "dayUnlockedFor") as? Date {
            return Calendar.current.isDate(unlockedDate, inSameDayAs: today)
        }
        return false
    }
    
    private func loadCurrentSchedule() {
        if let prefs = currentPreferences {
            bedtime = prefs.bedtime
            wakeBufferMinutes = prefs.wakeBufferMinutes
        } else {
            // Set defaults
            let calendar = Calendar.current
            bedtime = calendar.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
            wakeBufferMinutes = 30 // Default 30 minutes
        }
        hasChanges = false
    }
    
    private func saveSchedule() {
        // Create or update preferences
        if let existingPrefs = currentPreferences {
            existingPrefs.updateBedtime(bedtime)
            existingPrefs.updateWakeBuffer(wakeBufferMinutes)
        } else {
            let newPrefs = UserPreferences(
                bedtime: bedtime,
                wakeBufferMinutes: wakeBufferMinutes
            )
            modelContext.insert(newPrefs)
        }
        
        // Save to ScheduleManager with effective wake time (sunrise + buffer)
        guard let schedule = getCurrentSchedule() else {
            Logger.shared.logError("Failed to get current schedule for saving")
            return
        }
        ScheduleManager.shared.saveSchedule(bedtime: schedule.bedtime, waketime: schedule.waketime)
        
        // Force ScheduleManager to re-evaluate current state with new schedule
        ScheduleManager.shared.evaluateCurrentState()
        
        hasChanges = false
        showingSaveConfirmation = true
    }
}

// MARK: - Supporting Views

struct ScheduleProgressBar: View {
    let bedtime: Date
    let waketime: Date
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress fill
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.7), Color.blue.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * progressPercentage, height: 4)
                    .cornerRadius(2)
                
                // Current time indicator
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .offset(x: geometry.size.width * progressPercentage - 4)
            }
        }
        .frame(height: 8)
    }
    
    private var progressPercentage: CGFloat {
        let calendar = Calendar.current
        let now = Date()
        
        // Get today's bedtime and waketime
        let todayBedtime = calendar.date(
            bySettingHour: calendar.component(.hour, from: bedtime),
            minute: calendar.component(.minute, from: bedtime),
            second: 0,
            of: now
        ) ?? bedtime
        
        let tomorrowWaketime = calendar.date(byAdding: .day, value: 1, to: calendar.date(
            bySettingHour: calendar.component(.hour, from: waketime),
            minute: calendar.component(.minute, from: waketime),
            second: 0,
            of: now
        ) ?? waketime) ?? waketime
        
        // Calculate progress through the sleep cycle
        let totalDuration = tomorrowWaketime.timeIntervalSince(todayBedtime)
        let elapsed = now.timeIntervalSince(todayBedtime)
        
        let progress = elapsed / totalDuration
        return CGFloat(max(0, min(1, progress)))
    }
}

struct BedtimeSummary: View {
    let bedtime: Date
    
    var body: some View {
        let nextSleepTime = getNextSleepTime()
        Text("Next bedtime: \(nextSleepTime)")
    }
    
    private func getNextSleepTime() -> String {
        let calendar = Calendar.current
        let now = Date()
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        
        // Create today's bedtime
        guard let todayBedtime = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: calendar.component(.day, from: now),
            hour: bedtimeComponents.hour,
            minute: bedtimeComponents.minute
        )) else {
            return "Invalid time"
        }
        
        // If bedtime has passed today, show tomorrow's bedtime
        let targetBedtime = todayBedtime > now ? todayBedtime : 
            calendar.date(byAdding: .day, value: 1, to: todayBedtime) ?? todayBedtime
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        if calendar.isDateInToday(targetBedtime) {
            return "Today at \(formatter.string(from: targetBedtime))"
        } else {
            return "Tomorrow at \(formatter.string(from: targetBedtime))"
        }
    }
}

