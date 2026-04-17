import Foundation
import SwiftData

@Model
class ExtraEntry {
    var id: UUID
    var note: String
    var value: Double
    var createdAt: Date

    init(note: String, value: Double) {
        self.id = UUID()
        self.note = note
        self.value = value
        self.createdAt = Date()
    }
}
