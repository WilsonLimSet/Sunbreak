import Foundation
import SwiftData

@Model
final class EntitlementState {
    var isAuthorized: Bool
    var lastChecked: Date
    var authorizationType: String
    
    init(isAuthorized: Bool = false, authorizationType: String = "notDetermined") {
        self.isAuthorized = isAuthorized
        self.authorizationType = authorizationType
        self.lastChecked = Date()
    }
    
    func updateAuthorization(isAuthorized: Bool, type: String) {
        self.isAuthorized = isAuthorized
        self.authorizationType = type
        self.lastChecked = Date()
    }
}