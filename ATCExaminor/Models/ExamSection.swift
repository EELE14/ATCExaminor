import Foundation
import SwiftData

@Model
class ExamSection {
    var id: UUID
    var level: RatingLevel
    var displayName: String
    var passingThreshold: Double
    var orderIndex: Int
    @Relationship(deleteRule: .cascade) var groups: [CriterionGroup]

    init(
        level: RatingLevel,
        displayName: String,
        passingThreshold: Double,
        orderIndex: Int
    ) {
        self.id = UUID()
        self.level = level
        self.displayName = displayName
        self.passingThreshold = passingThreshold
        self.orderIndex = orderIndex
        self.groups = []
    }
}
