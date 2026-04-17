import SwiftUI

struct SectionHeaderView: View {
    let level: RatingLevel
    let session: Session

    private var criteria: [CriterionScore] {
        session.criterionScores.filter { $0.ratingLevel == level }
    }

    private var score: Double? {
        ScoringEngine.sectionScore(criteria: criteria)
    }

    private var threshold: Double {
        level.defaultPassingThreshold
    }

    private var achieved: Double {
        criteria.reduce(0.0) { $0 + ($1.mark?.rawValue ?? 0) }
    }

    private var total: Int { criteria.count }

    private var badge: BadgeState {
        guard let s = score else {
            let anyRated = criteria.contains { $0.mark != nil }
            return anyRated ? .warning : .pending
        }
        return s >= threshold ? .pass : .fail
    }

    private var badgeLabel: String {
        guard let s = score else { return "–" }
        return s >= threshold ? "Pass" : "Fail"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(level.displayName)
                .font(.system(size: 15, weight: .medium))

            Spacer()

            if let s = score {
                Text(String(format: "%.1f / %d · %.0f%%", achieved, total, s * 100))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))
            } else {
                let rated = criteria.filter { $0.mark != nil }.count
                Text("\(rated) / \(total) rated")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))
            }

            ScoreBadge(state: badge, customLabel: score == nil ? "–" : badgeLabel)

            Text("Threshold: \(String(format: "%.0f%%", threshold * 100))")
                .font(.system(size: 11))
                .foregroundStyle(Color(.tertiaryLabelColor))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
