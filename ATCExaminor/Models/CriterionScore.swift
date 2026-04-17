import Foundation
import SwiftData

@Model
class CriterionScore {
    var id: UUID
    var criterionText: String
    var groupLabel: String
    var mark: Mark?
    var note: String
    var orderIndex: Int
    var ratingLevel: RatingLevel

    init(
        criterionText: String,
        groupLabel: String,
        mark: Mark? = nil,
        note: String = "",
        orderIndex: Int,
        ratingLevel: RatingLevel
    ) {
        self.id = UUID()
        self.criterionText = criterionText
        self.groupLabel = groupLabel
        self.mark = mark
        self.note = note
        self.orderIndex = orderIndex
        self.ratingLevel = ratingLevel
    }
}
