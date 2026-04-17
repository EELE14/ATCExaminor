import SwiftUI
import SwiftData

struct SectionScoringView: View {
    let session: Session
    let vm: SessionViewModel
    let upToLevel: RatingLevel
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(upToLevel.requiredLevels, id: \.self) { level in
                    Section {
                        SectionBlock(session: session, level: level, isReadOnly: session.isComplete, onChanged: {
                            vm.touch(context: context)
                        })
                    } header: {
                        SectionHeaderView(level: level, session: session)
                            .background(.regularMaterial)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color(.separatorColor))
                                    .frame(height: 0.5)
                            }
                    }
                }

                ExtraPointsView(session: session, vm: vm, isReadOnly: session.isComplete)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}

private struct SectionBlock: View {
    let session: Session
    let level: RatingLevel
    var isReadOnly: Bool = false
    let onChanged: () -> Void

    private var criteria: [CriterionScore] {
        session.criterionScores
            .filter { $0.ratingLevel == level }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var groups: [(label: String, criteria: [CriterionScore])] {
        var seen: [String] = []
        var result: [(String, [CriterionScore])] = []
        for c in criteria {
            if !seen.contains(c.groupLabel) {
                seen.append(c.groupLabel)
                result.append((c.groupLabel, []))
            }
            if let idx = result.firstIndex(where: { $0.0 == c.groupLabel }) {
                result[idx].1.append(c)
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(groups, id: \.label) { group in
                if !group.label.isEmpty {
                    Text(group.label.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .kerning(0.5)
                        .foregroundStyle(Color(.secondaryLabelColor))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 6)
                }

                VStack(spacing: 0) {
                    ForEach(group.criteria) { criterion in
                        CriterionRow(criterion: criterion, onChanged: onChanged, isReadOnly: isReadOnly)
                            .padding(.horizontal, 16)

                        if criterion.id != group.criteria.last?.id {
                            Rectangle()
                                .fill(Color(.separatorColor))
                                .frame(height: 0.5)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }

            // Section score bar
            sectionScoreBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
        }
    }

    private var sectionScoreBar: some View {
        let sectionCriteria = criteria
        let score = ScoringEngine.sectionScore(criteria: sectionCriteria)
        let threshold = level.defaultPassingThreshold
        let total = sectionCriteria.count
        let achieved = sectionCriteria.reduce(0.0) { $0 + ($1.mark?.rawValue ?? 0) }

        let badge: BadgeState = {
            guard let s = score else {
                let anyRated = sectionCriteria.contains { $0.mark != nil }
                return anyRated ? .warning : .pending
            }
            return s >= threshold ? .pass : .fail
        }()

        return HStack(spacing: 8) {
            if let s = score {
                Text(String(format: "%.1f / %d · %.0f%%", achieved, total, s * 100))
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))
            } else {
                let rated = sectionCriteria.filter { $0.mark != nil }.count
                Text("\(rated) / \(total) rated")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))
            }
            ScoreBadge(state: badge, customLabel: score == nil ? "–" : (score! >= threshold ? "Pass" : "Fail"))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }
}
