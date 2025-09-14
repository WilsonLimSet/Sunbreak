import Foundation
import SwiftData
import FamilyControls

@Model
final class SelectionRecord {
    var selectionData: Data?
    var createdAt: Date
    var updatedAt: Date
    
    // Shared JSON coders to avoid creating new instances on each access
    private static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    @Transient
    private var _cachedSelection: FamilyActivitySelection?
    @Transient
    private var _lastDecodedDataHash: Int?
    
    @Transient
    var familyActivitySelection: FamilyActivitySelection? {
        get {
            guard let data = selectionData else {
                _cachedSelection = nil
                _lastDecodedDataHash = nil
                return nil
            }
            
            let currentHash = data.hashValue
            
            // Return cached value if data hasn't changed
            if let cachedSelection = _cachedSelection,
               let lastHash = _lastDecodedDataHash,
               lastHash == currentHash {
                return cachedSelection
            }
            
            // Decode and cache the result
            do {
                let selection = try Self.jsonDecoder.decode(FamilyActivitySelection.self, from: data)
                _cachedSelection = selection
                _lastDecodedDataHash = currentHash
                return selection
            } catch {
                _cachedSelection = nil
                _lastDecodedDataHash = nil
                return nil
            }
        }
        set {
            do {
                if let newValue = newValue {
                    selectionData = try Self.jsonEncoder.encode(newValue)
                } else {
                    selectionData = nil
                }
                updatedAt = Date()
                
                // Update cache
                _cachedSelection = newValue
                _lastDecodedDataHash = selectionData?.hashValue
            } catch {
                selectionData = nil
                _cachedSelection = nil
                _lastDecodedDataHash = nil
            }
        }
    }
    
    init(selection: FamilyActivitySelection? = nil) {
        self.createdAt = Date()
        self.updatedAt = Date()
        
        if let selection = selection {
            do {
                self.selectionData = try Self.jsonEncoder.encode(selection)
                self._cachedSelection = selection
                self._lastDecodedDataHash = self.selectionData?.hashValue
            } catch {
                self.selectionData = nil
                self._cachedSelection = nil
                self._lastDecodedDataHash = nil
            }
        } else {
            self.selectionData = nil
            self._cachedSelection = nil
            self._lastDecodedDataHash = nil
        }
    }
}