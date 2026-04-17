import Foundation
import SwiftData

@Observable
class SessionViewModel {
    var session: Session
    var selectedPanel: Panel = .section(.s1) {
        didSet {
            if case .section(let level) = selectedPanel {
                activeSectionLevel = level
            }
        }
    }
    private(set) var activeSectionLevel: RatingLevel = .s1
    var showExportSuccess = false
    var exportError: String? = nil
    var showExportIncompleteAlert = false
    var showExportErrorAlert = false

    enum Panel: Hashable {
        case section(RatingLevel)
        case extraPoints
        case finalSummary

        var isSection: Bool {
            if case .section = self { return true }
            return false
        }
    }

    init(session: Session) {
        self.session = session
        let firstLevel = session.targetRating.requiredLevels.first ?? .s1
        self.activeSectionLevel = firstLevel
        self.selectedPanel = .section(firstLevel)
    }

    // MARK: - Scoring

    private var finalThreshold: Double {
        let stored = UserDefaults.standard.double(forKey: "finalPassingThreshold")
        return stored == 0 ? 84.0 : stored
    }

    func sectionScore(for level: RatingLevel) -> Double? {
        let criteria = session.criterionScores.filter { $0.ratingLevel == level }
        return ScoringEngine.sectionScore(criteria: criteria)
    }

    func sectionThreshold(for level: RatingLevel) -> Double {
        level.defaultPassingThreshold
    }

    func sectionPassed(for level: RatingLevel) -> Bool? {
        guard let score = sectionScore(for: level) else { return nil }
        return ScoringEngine.sectionPassed(score: score, threshold: sectionThreshold(for: level))
    }

    var finalScore: Double? {
        ScoringEngine.finalScore(session: session)
    }

    var sectionAverage: Double? {
        ScoringEngine.sectionAverage(session: session)
    }

    var extraDelta: Double {
        ScoringEngine.extraDelta(session: session)
    }

    var overallPassed: Bool? {
        ScoringEngine.overallPassed(session: session, finalThreshold: finalThreshold)
    }

    var allCriteriaRated: Bool {
        session.criterionScores.allSatisfy { $0.mark != nil }
    }

    // MARK: - Progress bar helpers

    var progressFraction: Double {
        guard let score = finalScore else {
            let rated = session.criterionScores.filter { $0.mark != nil }.count
            let total = session.criterionScores.count
            guard total > 0 else { return 0 }
            return Double(rated) / Double(total)
        }
        return min(max(score / 100.0, 0), 1)
    }

    // MARK: - Current section for bottom bar

    var currentSectionLevel: RatingLevel? {
        if case .section(let level) = selectedPanel { return level }
        return nil
    }

    var currentSectionScore: Double? {
        guard let level = currentSectionLevel else { return nil }
        return sectionScore(for: level)
    }

    // MARK: - Persistence

    func touch(context: ModelContext) {
        session.lastModified = Date()
        try? context.save()
    }
}
