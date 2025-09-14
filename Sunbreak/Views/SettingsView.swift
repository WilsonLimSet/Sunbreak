import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var authManager: ScreenTimeAuthManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                
                PermissionsSection(authManager: authManager)
                
                AboutSection(
                    showingAbout: $showingAbout
                )
                
                
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
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



