import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Image("Transparent")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.top, 40)
                    
                    Text("Sunbreak")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Better mornings start with better nights")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        Text("Sunbreak helps you build healthier sleep habits by restricting distracting apps during bedtime hours.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            InfoRow(title: "How It Works", description: "Set your bedtime schedule and choose apps to restrict. Apps unlock automatically after sunrise with optional buffer time.")
                            
                            InfoRow(title: "Privacy First", description: "Your app usage data never leaves your device. We don't track, store, or analyze your personal information.")
                            
                            InfoRow(title: "Science-Based", description: "Exposure to natural daylight helps regulate your circadian rhythm and improves sleep quality.")
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        SectionHeader(title: "Your Privacy Matters")
                        
                        Text("Sunbreak is designed with privacy at its core. We believe your data belongs to you.")
                            .foregroundColor(.secondary)
                        
                        SectionHeader(title: "Data Collection")
                        
                        PrivacyPoint(
                            icon: "lock.shield.fill",
                            title: "Screen Time Data",
                            description: "All Screen Time data remains on your device. We cannot see which apps you use or how often."
                        )
                        
                        
                        PrivacyPoint(
                            icon: "location.fill",
                            title: "Location Data",
                            description: "If granted, location is used only to calculate local sunrise/sunset times. This data is never shared."
                        )
                    }
                    
                    Group {
                        SectionHeader(title: "Data Storage")
                        
                        Text("All your preferences, schedules, and app selections are stored locally on your device using Apple's secure storage systems.")
                            .foregroundColor(.secondary)
                        
                        SectionHeader(title: "Third-Party Services")
                        
                        Text("Sunbreak does not use any third-party analytics, tracking, or advertising services.")
                            .foregroundColor(.secondary)
                        
                        SectionHeader(title: "Your Rights")
                        
                        Text("You can delete all your data at any time by removing the app. You can also reset your settings from within the app.")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Questions?")
                            .fontWeight(.semibold)
                        Link("Contact us at privacy@sunbreak.app", destination: URL(string: "mailto:privacy@sunbreak.app")!)
                            .font(.subheadline)
                    }
                    
                    Text("Last updated: January 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top)
    }
}

struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("BrandOrange"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}