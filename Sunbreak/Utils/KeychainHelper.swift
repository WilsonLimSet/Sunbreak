import Foundation
import Security

final class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .itemNotFound:
                return "API key not found in Keychain"
            case .duplicateItem:
                return "API key already exists in Keychain"
            case .invalidItemFormat:
                return "Invalid API key format"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    func store(apiKey: String, service: String = "GeminiAPI") throws {
        guard !apiKey.isEmpty else {
            throw KeychainError.invalidItemFormat
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api_key",
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "api_key"
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: apiKey.data(using: .utf8)!
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus != errSecSuccess {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func retrieve(service: String = "GeminiAPI") throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let apiKey = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidItemFormat
            }
            return apiKey
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func delete(service: String = "GeminiAPI") throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api_key"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break // Success or item didn't exist
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
}