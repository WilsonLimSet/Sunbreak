import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    @StateObject private var locationManager = LocationManager()
    @State private var showingAbout = false
    @State private var useManualSunrise = false
    @State private var manualSunriseTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    var body: some View {
        NavigationView {
            Form {
                SunriseSection(
                    locationManager: locationManager,
                    useManualSunrise: $useManualSunrise,
                    manualSunriseTime: $manualSunriseTime
                )

                PermissionsSection(authManager: authManager)

                AboutSection(
                    showingAbout: $showingAbout
                )
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .onAppear {
                loadSunriseSettings()
            }
        }
    }

    private func loadSunriseSettings() {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        useManualSunrise = userDefaults?.bool(forKey: "useManualSunrise") ?? false
        if let savedTime = userDefaults?.object(forKey: "manualSunriseTime") as? Date {
            manualSunriseTime = savedTime
        }
    }
}

struct SunriseSection: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var useManualSunrise: Bool
    @Binding var manualSunriseTime: Date

    var body: some View {
        Section("Sunrise Time") {
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color("BrandOrange"))
                    Text("Using Location")
                    Spacer()
                    if let sunrise = locationManager.sunrise {
                        Text(sunrise.formatted(date: .omitted, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Toggle(isOn: $useManualSunrise) {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(Color("BrandOrange"))
                        Text("Manual Sunrise")
                    }
                }
                .onChange(of: useManualSunrise) { oldValue, newValue in
                    saveManualSunrisePreference(newValue)
                }

                if useManualSunrise {
                    DatePicker("Sunrise Time", selection: $manualSunriseTime, displayedComponents: .hourAndMinute)
                        .onChange(of: manualSunriseTime) { oldTime, newTime in
                            saveManualSunriseTime(newTime)
                        }
                }

                if locationManager.authorizationStatus == .denied {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.slash")
                                .foregroundColor(.red)
                            Text("Enable Location in Settings")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func saveManualSunrisePreference(_ useManual: Bool) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(useManual, forKey: "useManualSunrise")
        if useManual {
            saveManualSunriseTime(manualSunriseTime)
        }
        // Reload sunrise times in LocationManager
        locationManager.handleTimezoneChange()
    }

    private func saveManualSunriseTime(_ time: Date) {
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")
        userDefaults?.set(time, forKey: "manualSunriseTime")
        userDefaults?.set(true, forKey: "useManualSunrise")
        // Reload sunrise times in LocationManager
        locationManager.handleTimezoneChange()
    }
}

struct PermissionsSection: View {
    @ObservedObject var authManager: ScreenTimeAuthManager
    
    var body: some View {
        Section("Permissions") {
            HStack {
                Image(systemName: "hourglass")
                    .foregroundColor(Color("BrandOrange"))
                Text("Screen Time")
                Spacer()
                Image(systemName: authManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(authManager.isAuthorized ? .green : .red)
            }
        }
    }
}

struct AboutSection: View {
    @Binding var showingAbout: Bool
    
    var body: some View {
        Section("About") {
            Button(action: { showingAbout = true }) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("About Sunbreak")
                        .foregroundColor(.primary)
                }
            }
            
            Button(action: {
                // Force open in Safari instead of default browser
                if let url = URL(string: "https://www.getsunbreak.com/privacy") {
                    UIApplication.shared.open(url, options: [.universalLinksOnly: false], completionHandler: nil)
                }
            }) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://x.com/WilsonLimSet")!) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Color("BrandOrange"))
                    Text("Contact Support")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Rate Sunbreak")
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                if let url = URL(string: "https://apps.apple.com/app/id6752121964?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}



