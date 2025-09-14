import FamilyControls
import SwiftUI

@MainActor
final class ScreenTimeAuthManager: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    @Published var showAuthorizationError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSimulator: Bool = false
    
    private let center = AuthorizationCenter.shared
    
    init() {
        #if targetEnvironment(simulator)
        isSimulator = true
        #else
        isSimulator = false
        #endif
        
        Task {
            await checkAuthorization()
        }
    }
    
    func checkAuthorization() async {
        if isSimulator {
            // On simulator, we can't get real Screen Time permissions
            authorizationStatus = .notDetermined
            isAuthorized = false
            return
        }
        
        authorizationStatus = center.authorizationStatus
        isAuthorized = authorizationStatus == .approved
    }
    
    func requestAuthorization() async {
        if isSimulator {
            errorMessage = "Screen Time permissions cannot be granted on the iOS Simulator. Please test on a physical device to use Screen Time features."
            showAuthorizationError = true
            return
        }
        
        
        do {
            try await center.requestAuthorization(for: .individual)
            
            // Re-check status after request
            authorizationStatus = center.authorizationStatus
            isAuthorized = authorizationStatus == .approved
            
            
            if !isAuthorized {
                if authorizationStatus == .denied {
                    errorMessage = "Screen Time authorization was denied. Please enable it in Settings → Screen Time → App & Website Activity."
                } else {
                    errorMessage = "Screen Time authorization status: \(authorizationStatus). Please check your Screen Time settings."
                }
                showAuthorizationError = true
            }
        } catch let error as NSError {
            authorizationStatus = .denied
            isAuthorized = false
            
            
            // More specific error messages
            if error.domain == "FamilyControlsError" {
                switch error.code {
                case 2:
                    errorMessage = "Screen Time is not enabled on this device. Please go to Settings → Screen Time and set it up first."
                case 3:
                    errorMessage = "Family Controls authorization is restricted. Please check Settings → Screen Time → Content & Privacy Restrictions."
                case 4:
                    errorMessage = "Authorization was cancelled. Please try again."
                default:
                    errorMessage = "Screen Time error (code \(error.code)): \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to request Screen Time authorization: \(error.localizedDescription)"
            }
            showAuthorizationError = true
        }
    }
    
    func revokeAuthorization() async {
        center.revokeAuthorization { result in
            switch result {
            case .success:
                Task { @MainActor in
                    self.authorizationStatus = .notDetermined
                    self.isAuthorized = false
                }
            case .failure(let error):
                Task { @MainActor in
                    self.errorMessage = "Failed to revoke authorization: \(error.localizedDescription)"
                    self.showAuthorizationError = true
                }
            }
        }
    }
}