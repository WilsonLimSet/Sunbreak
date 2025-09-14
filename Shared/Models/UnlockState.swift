import Foundation
import SwiftData

@Model
final class UnlockState {
    var dayUnlockedFor: Date?
    var lastSuccessAt: Date?
    var isCurrentlyUnlocked: Bool
    
    init() {
        self.isCurrentlyUnlocked = false
    }
    
    func unlockForToday() {
        let calendar = Calendar.current
        self.dayUnlockedFor = calendar.startOfDay(for: Date())
        self.lastSuccessAt = Date()
        self.isCurrentlyUnlocked = true
    }
    
    func checkIfStillUnlocked() -> Bool {
        guard let unlockedDate = dayUnlockedFor else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.isDate(unlockedDate, inSameDayAs: today)
    }
    
    func resetUnlock() {
        self.dayUnlockedFor = nil
        self.isCurrentlyUnlocked = false
    }
}