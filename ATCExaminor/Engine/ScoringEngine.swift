import Foundation

struct ScoringEngine {

    static func sectionScore(criteria: [CriterionScore]) -> Double? {
        guard !criteria.isEmpty else { return nil }
        guard criteria.allSatisfy({ $0.mark != nil }) else { return nil }
        let total = Double(criteria.count)
        let achieved = criteria.reduce(0.0) { $0 + ($1.mark?.rawValue ?? 0) }
        return achieved / total
    }

    static func sectionPassed(score: Double, threshold: Double) -> Bool {
        score >= threshold
    }

    static func extraDelta(session: Session) -> Double {
        let totalCriteria = Double(session.criterionScores.count)
        guard totalCriteria > 0 else { return 0 }
        return session.extraEntries.reduce(0.0) { $0 + $1.value } / totalCriteria * 100.0
    }

    static func finalScore(session: Session) -> Double? {
        let activeLevels = session.targetRating.requiredLevels
        var sectionPercentages: [Double] = []

        for level in activeLevels {
            let criteria = session.criterionScores.filter { $0.ratingLevel == level }
            guard let score = sectionScore(criteria: criteria) else { return nil }
            sectionPercentages.append(score * 100.0)
        }

        guard !sectionPercentages.isEmpty else { return nil }
        let sectionAverage = sectionPercentages.reduce(0, +) / Double(sectionPercentages.count)
        let delta = extraDelta(session: session)
        return sectionAverage + delta
    }

    static func sectionAverage(session: Session) -> Double? {
        let activeLevels = session.targetRating.requiredLevels
        var sectionPercentages: [Double] = []

        for level in activeLevels {
            let criteria = session.criterionScores.filter { $0.ratingLevel == level }
            guard let score = sectionScore(criteria: criteria) else { return nil }
            sectionPercentages.append(score * 100.0)
        }

        guard !sectionPercentages.isEmpty else { return nil }
        return sectionPercentages.reduce(0, +) / Double(sectionPercentages.count)
    }

    static func overallPassed(
        session: Session,
        sectionThresholds: [RatingLevel: Double] = [:],
        finalThreshold: Double = 84.0
    ) -> Bool? {
        let activeLevels = session.targetRating.requiredLevels
        for level in activeLevels {
            let criteria = session.criterionScores.filter { $0.ratingLevel == level }
            guard let score = sectionScore(criteria: criteria) else { return nil }
            let threshold = sectionThresholds[level] ?? level.defaultPassingThreshold
            if !sectionPassed(score: score, threshold: threshold) { return false }
        }
        guard let final = finalScore(session: session) else { return nil }
        return final >= finalThreshold
    }
}
