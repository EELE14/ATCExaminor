import Foundation
import SwiftData

@Model
class Session {
    var id: UUID
    var candidateName: String
    var icao: String
    var examinerName: String
    var targetRating: RatingLevel
    var createdAt: Date
    var lastModified: Date
    var isComplete: Bool
    @Relationship(deleteRule: .cascade) var criterionScores: [CriterionScore]
    @Relationship(deleteRule: .cascade) var extraEntries: [ExtraEntry]

    init(
        candidateName: String,
        icao: String,
        examinerName: String,
        targetRating: RatingLevel
    ) {
        self.id = UUID()
        self.candidateName = candidateName
        self.icao = icao
        self.examinerName = examinerName
        self.targetRating = targetRating
        self.createdAt = Date()
        self.lastModified = Date()
        self.isComplete = false
        self.criterionScores = []
        self.extraEntries = []
    }
}
