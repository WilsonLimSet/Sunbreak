import UIKit
import SwiftUI

// iOS 17.0 Compatibility Helpers
struct iOSCompatibility {
    
    // Check if we're running on iOS 17.0 or later
    static var isiOS17OrLater: Bool {
        if #available(iOS 17.0, *) {
            return true
        } else {
            return false
        }
    }
    
    // Check if we're running on the minimum supported version
    static var isMinimumSupported: Bool {
        return isiOS17OrLater
    }
    
    // Safe way to handle onChange syntax differences
    static func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (V, V) -> Void
    ) -> some ViewModifier {
        return OnChangeCompatibilityModifier(value: value, action: action)
    }
}

// ViewModifier to handle onChange syntax compatibility
private struct OnChangeCompatibilityModifier<V: Equatable>: ViewModifier {
    let value: V
    let action: (V, V) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: value) { oldValue, newValue in
                action(oldValue, newValue)
            }
        } else {
            // Fallback for older iOS versions if needed
            content.onChange(of: value) { newValue in
                action(value, newValue) // We don't have old value in iOS 16
            }
        }
    }
}

// Screen Time API compatibility checks
extension iOSCompatibility {
    
    static func checkScreenTimeSupport() -> Bool {
        // FamilyControls framework availability
        if #available(iOS 16.0, *) {
            return true
        } else {
            return false
        }
    }
    
    static func checkSwiftDataSupport() -> Bool {
        // SwiftData framework availability
        if #available(iOS 17.0, *) {
            return true
        } else {
            return false
        }
    }
}

// Camera API compatibility
extension iOSCompatibility {
    
    static func checkCameraSupport() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static func checkAVFoundationSupport() -> Bool {
        // AVFoundation is available on all supported iOS versions
        return true
    }
}

// Background task compatibility
extension iOSCompatibility {
    
    static func scheduleBackgroundTask(identifier: String, handler: @escaping () -> Void) {
        if #available(iOS 13.0, *) {
            // Use BackgroundTasks framework
        } else {
            // Fallback for older versions
        }
    }
}

// Safe casting helpers for iOS version compatibility
extension iOSCompatibility {
    
    static func safeUnwrap<T>(_ optional: T?, fallback: T) -> T {
        return optional ?? fallback
    }
    
    static func safeAsync<T>(
        operation: @escaping () async throws -> T,
        fallback: T
    ) async -> T {
        do {
            return try await operation()
        } catch {
            return fallback
        }
    }
}