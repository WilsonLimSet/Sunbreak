import Foundation
import SwiftUI

// MARK: - Standardized Error Types
enum SunbreakError: LocalizedError, Equatable {
    case locationPermissionDenied
    case locationUnavailable
    case screenTimePermissionDenied
    case screenTimeUnavailable
    case networkError(String)
    case dataCorruption(String)
    case memoryPressure
    case apiKeyMissing
    case invalidConfiguration(String)
    case userCancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .locationPermissionDenied:
            return "Location permission denied. Please enable location access in Settings to calculate sunrise times."
        case .locationUnavailable:
            return "Location services are not available."
        case .screenTimePermissionDenied:
            return "Screen Time permission denied. Please enable Screen Time access in Settings to manage app restrictions."
        case .screenTimeUnavailable:
            return "Screen Time controls are not available on this device."
        case .networkError(let details):
            return "Network error: \(details)"
        case .dataCorruption(let context):
            return "Data corruption detected in \(context). Please restart the app."
        case .memoryPressure:
            return "Insufficient memory to complete this operation."
        case .apiKeyMissing:
            return "API key not configured. Please contact support."
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
        case .userCancelled:
            return "Operation cancelled by user."
        case .unknown(let details):
            return "An unexpected error occurred: \(details)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .locationPermissionDenied, .screenTimePermissionDenied:
            return "Permission denied by user"
        case .locationUnavailable, .screenTimeUnavailable:
            return "Feature not available on device"
        case .networkError, .dataCorruption, .invalidConfiguration, .unknown:
            return "System error"
        case .memoryPressure:
            return "Insufficient resources"
        case .apiKeyMissing:
            return "Configuration error"
        case .userCancelled:
            return nil
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .locationPermissionDenied, .screenTimePermissionDenied:
            return "Go to Settings > Privacy & Security and enable the required permissions for Sunbreak."
        case .locationUnavailable, .screenTimeUnavailable:
            return "This feature requires hardware that is not available on your device."
        case .networkError:
            return "Check your internet connection and try again."
        case .dataCorruption:
            return "Restart the app to reset the corrupted data."
        case .memoryPressure:
            return "Close other apps to free up memory and try again."
        case .apiKeyMissing:
            return "Please contact support to resolve this configuration issue."
        case .invalidConfiguration:
            return "Please restart the app or contact support."
        case .userCancelled:
            return nil
        case .unknown:
            return "Please restart the app or contact support if the problem persists."
        }
    }
    
    /// Severity level for logging and user feedback
    var severity: ErrorSeverity {
        switch self {
        case .userCancelled:
            return .info
        case .locationPermissionDenied, .screenTimePermissionDenied:
            return .warning
        case .locationUnavailable, .screenTimeUnavailable, .memoryPressure:
            return .warning
        case .networkError:
            return .error
        case .dataCorruption, .apiKeyMissing, .invalidConfiguration, .unknown:
            return .critical
        }
    }
}

enum ErrorSeverity: String, CaseIterable {
    case info = "INFO"
    case warning = "WARNING" 
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var emoji: String {
        switch self {
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
}

// MARK: - Error Handler
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: SunbreakError?
    @Published var showError = false
    
    private init() {}
    
    /// Handle an error with optional user presentation
    func handle(_ error: Error, context: String = "", showToUser: Bool = true) {
        let sunbreakError = convertToSunbreakError(error, context: context)
        
        // Log the error
        logError(sunbreakError, context: context)
        
        // Show to user if requested and not user-cancelled
        if showToUser && sunbreakError != .userCancelled {
            DispatchQueue.main.async {
                self.currentError = sunbreakError
                self.showError = true
            }
        }
    }
    
    /// Handle a SunbreakError directly
    func handle(_ error: SunbreakError, context: String = "", showToUser: Bool = true) {
        logError(error, context: context)
        
        if showToUser && error != .userCancelled {
            DispatchQueue.main.async {
                self.currentError = error
                self.showError = true
            }
        }
    }
    
    /// Clear current error
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showError = false
        }
    }
    
    func convertToSunbreakError(_ error: Error, context: String) -> SunbreakError {
        // Convert common system errors to SunbreakErrors
        if let urlError = error as? URLError {
            return .networkError("Network request failed: \(urlError.localizedDescription)")
        }
        
        if error.localizedDescription.lowercased().contains("permission") {
            if context.lowercased().contains("location") {
                return .locationPermissionDenied
            } else if context.lowercased().contains("screen") {
                return .screenTimePermissionDenied
            }
        }
        
        if error.localizedDescription.lowercased().contains("cancelled") {
            return .userCancelled
        }
        
        return .unknown(error.localizedDescription)
    }
    
    private func logError(_ error: SunbreakError, context: String) {
        let contextStr = context.isEmpty ? "" : " [\(context)]"
        let logMessage = "\(error.severity.emoji) [\(error.severity.rawValue)]\(contextStr) \(error.localizedDescription)"
        
        print(logMessage)
        
        // In a production app, you might want to send critical errors to a crash reporting service
        if error.severity == .critical {
            // CrashReporting.logError(error, context: context)
        }
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.localizedDescription)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }
    }
}

extension View {
    func errorAlert() -> some View {
        modifier(ErrorAlertModifier())
    }
}

// MARK: - Result Extensions for Error Handling
extension Result where Failure == Error {
    func mapSunbreakError(context: String = "") -> Result<Success, SunbreakError> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            let sunbreakError = ErrorHandler.shared.convertToSunbreakError(error, context: context)
            return .failure(sunbreakError)
        }
    }
}