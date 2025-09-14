import ManagedSettings
import ManagedSettingsUI
import UIKit
import SwiftUI

public class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override init() {
        super.init()
    }
    
    private func getTimeUntilSunrise() -> String {

        let calendar = Calendar.current
        let now = Date()

        // Create UserDefaults for app group
        let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared")

        // Get wake time from user defaults
        let waketimeData = userDefaults?.data(forKey: "userWaketime")
        let waketime: Date

        if let waketimeData = waketimeData,
           let savedWaketime = try? JSONDecoder().decode(Date.self, from: waketimeData) {
            waketime = savedWaketime
        } else {
            // Fallback: use sunrise + buffer or default 7 AM tomorrow
            let sunrise = userDefaults?.object(forKey: "sunrise") as? Date
            let wakeBufferMinutes = userDefaults?.integer(forKey: "wakeBufferMinutes") ?? 30

            if let sunrise = sunrise {
                waketime = calendar.date(byAdding: .minute, value: wakeBufferMinutes, to: sunrise) ?? sunrise
            } else {
                // Default to 7 AM tomorrow
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.day! += 1
                components.hour = 7
                components.minute = 0
                waketime = calendar.date(from: components) ?? now
            }
        }

        // Calculate time until wake
        var timeUntil = waketime.timeIntervalSince(now)

        // If wake time is in the past, calculate for tomorrow
        if timeUntil < 0 {
            let tomorrowWake = calendar.date(byAdding: .day, value: 1, to: waketime) ?? waketime
            timeUntil = tomorrowWake.timeIntervalSince(now)
        }


        let hours = Int(timeUntil) / 3600
        let minutes = Int(timeUntil) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "Soon"
        }
    }
    
    
    public override func configuration(shielding application: Application) -> ShieldConfiguration {

        let timeUntilWake = getTimeUntilSunrise()

        // Pure black background to match Sunbreak logo
        let darkBackground = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        // Better subtitle text
        let subtitleText = "Apps blocked for \(timeUntilWake) more"

        // Try transparent logo first, fallback to black background logo
        let logoImage = UIImage(named: "Transparent") ?? UIImage(named: "SunbreakLogo") ?? UIImage(systemName: "sun.horizon.fill")?.withTintColor(.orange, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark, // Clean dark blur
            backgroundColor: darkBackground,
            icon: logoImage,
            title: ShieldConfiguration.Label(
                text: "Sunbreak 🌅",
                color: UIColor.white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor(white: 0.8, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Back to Sleep",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(white: 0.2, alpha: 0.8), // Clean gray button
            secondaryButtonLabel: nil
        )
    }
    
    public override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }
    
    public override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {

        let timeUntilWake = getTimeUntilSunrise()

        // Pure black background to match Sunbreak logo
        let darkBackground = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        // Better subtitle text
        let subtitleText = "Apps blocked for \(timeUntilWake) more"

        // Try transparent logo first, fallback to black background logo
        let logoImage = UIImage(named: "Transparent") ?? UIImage(named: "SunbreakLogo") ?? UIImage(systemName: "sun.horizon.fill")?.withTintColor(.orange, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark, // Clean dark blur
            backgroundColor: darkBackground,
            icon: logoImage,
            title: ShieldConfiguration.Label(
                text: "Sunbreak 🌅",
                color: UIColor.white
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor(white: 0.8, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Back to Sleep",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(white: 0.2, alpha: 0.8), // Clean gray button
            secondaryButtonLabel: nil
        )
    }
}

// Shield Action Handler
public class ShieldActionExtension: ShieldActionDelegate {
    
    
    public override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // When time button is pressed, just close the shield
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    public override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            handleUnlockRequest(completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    public override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            handleUnlockRequest(completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    private func handleUnlockRequest(completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Check if already unlocked for today
        guard let userDefaults = UserDefaults(suiteName: "group.com.sunbreak.shared") else {
            completionHandler(.close)
            return
        }
        
        if let unlockedDate = userDefaults.object(forKey: "dayUnlockedFor") as? Date {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            if calendar.isDate(unlockedDate, inSameDayAs: today) {
                // Already unlocked today, defer to remove shield
                completionHandler(.defer)
                return
            }
        }
        
        // Not unlocked yet, close shield and prompt user to open app
        userDefaults.set(true, forKey: "shouldShowUnlockFlow")
        completionHandler(.close)
    }
    
}