import Foundation
import os.log

final class Logger {
    static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.sunbreak.app"
    
    private lazy var onboardingLogger = os.Logger(subsystem: subsystem, category: "Onboarding")
    private lazy var scheduleLogger = os.Logger(subsystem: subsystem, category: "Schedule")
    private lazy var locationLogger = os.Logger(subsystem: subsystem, category: "Location")
    private lazy var generalLogger = os.Logger(subsystem: subsystem, category: "General")
    
    private init() {}
    
    // MARK: - Public Logging Methods
    
    func logOnboarding(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        onboardingLogger.log(level: type, "\(message)")
        #endif
    }
    
    func logSchedule(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        scheduleLogger.log(level: type, "\(message)")
        #endif
    }
    
    func logLocation(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        locationLogger.log(level: type, "\(message)")
        #endif
    }
    
    
    func log(_ message: String, type: OSLogType = .default) {
        #if DEBUG
        generalLogger.log(level: type, "\(message)")
        #endif
    }
    
    func logError(_ message: String, error: Error? = nil) {
        #if DEBUG
        let errorMessage = error != nil ? "\(message): \(error!.localizedDescription)" : message
        generalLogger.log(level: .error, "\(errorMessage)")
        #endif
    }
}