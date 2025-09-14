import Foundation
import UIKit

final class TimezoneHelper {
    static let shared = TimezoneHelper()
    private init() {}
    
    private var _userTimeZone: TimeZone = .current
    private let lock = NSLock()
    
    /// The user's current timezone - updated when app enters background/foreground
    var userTimeZone: TimeZone {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _userTimeZone
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _userTimeZone = newValue
        }
    }
    
    /// Calendar using the user's timezone
    var userCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = userTimeZone
        return calendar
    }
    
    /// Update timezone when system timezone changes
    func updateTimezone() {
        userTimeZone = .current
        Logger.shared.log("[TimezoneHelper] Updated timezone to: \(userTimeZone.identifier)")
        
        // Post notification for interested parties
        NotificationCenter.default.post(
            name: .timezoneDidChange,
            object: nil,
            userInfo: ["timezone": userTimeZone]
        )
    }
    
    /// Convert a time (hour, minute) to Date in user's timezone for today
    func timeToDate(hour: Int, minute: Int, date: Date = Date()) -> Date? {
        let calendar = userCalendar
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.nanosecond = 0
        
        return calendar.date(from: components)
    }
    
    /// Extract hour and minute components from a date in user's timezone
    func timeComponents(from date: Date) -> (hour: Int, minute: Int) {
        let calendar = userCalendar
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
    
    /// Check if current time is between bedtime and waketime, handling timezone and midnight crossover
    func isCurrentlyInBedtimeWindow(bedtime: Date, waketime: Date, now: Date = Date()) -> Bool {
        // Get time components in user's timezone
        let nowComponents = timeComponents(from: now)
        let bedComponents = timeComponents(from: bedtime)
        let wakeComponents = timeComponents(from: waketime)
        
        let currentMinutes = nowComponents.hour * 60 + nowComponents.minute
        let bedMinutes = bedComponents.hour * 60 + bedComponents.minute
        let wakeMinutes = wakeComponents.hour * 60 + wakeComponents.minute
        
        // Handle midnight crossover (e.g., 22:00 to 07:00)
        if bedMinutes > wakeMinutes {
            // Schedule crosses midnight
            return currentMinutes >= bedMinutes || currentMinutes < wakeMinutes
        } else {
            // Schedule is within same day
            return currentMinutes >= bedMinutes && currentMinutes < wakeMinutes
        }
    }
    
    /// Get next occurrence of a time (for scheduling)
    func nextOccurrence(of time: Date, after date: Date = Date()) -> Date? {
        let calendar = userCalendar
        let timeComponents = timeComponents(from: time)
        
        // Try today first
        if let todayTime = timeToDate(hour: timeComponents.hour, minute: timeComponents.minute, date: date),
           todayTime > date {
            return todayTime
        }
        
        // Try tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) {
            return timeToDate(hour: timeComponents.hour, minute: timeComponents.minute, date: tomorrow)
        }
        
        return nil
    }
    
    /// Check if two dates are on the same day in user's timezone
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return userCalendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// Get date components in user's timezone
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        return userCalendar.dateComponents(components, from: date)
    }
}

extension Notification.Name {
    static let timezoneDidChange = Notification.Name("TimezoneDidChange")
}

// MARK: - App Lifecycle Integration
extension TimezoneHelper {
    func startMonitoring() {
        // Monitor timezone changes
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTimezone()
        }
        
        // Monitor app lifecycle for timezone updates
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTimezone()
        }
    }
    
    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }
}