import SwiftUI
import SwiftData

struct FinalSummaryView: View {
    let session: Session
    let vm: SessionViewModel
    @Environment(\.modelContext) private var context

    private var finalThreshold: Double {
        UserDefaults.standard.double(forKey: "finalPassingThreshold").nonZeroOr(84.0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {


                sectionResultsTable

                Divider()


                extraPointsSection

                Divider()

                finalScoreBlock

                Divider()

                completeButton
            }
            .padding(16)
        }
    }

    // MARK: - Section results table

    private var sectionResultsTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Section Results")
                .font(.system(size: 15, weight: .medium))

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    tableCell("Section", width: 160, isHeader: true)
                    tableCell("Score", width: 80, isHeader: true)
                    tableCell("%", width: 70, isHeader: true)
                    tableCell("Threshold", width: 90, isHeader: true)
                    tableCell("Result", width: 80, isHeader: true)
                }
                .background(Color(.controlBackgroundColor))

                Rectangle()
                    .fill(Color(.separatorColor))
                    .frame(height: 0.5)

                ForEach(session.targetRating.requiredLevels, id: \.self) { level in
                    sectionRow(for: level)
                    if level != session.targetRating.requiredLevels.last {
                        Rectangle()
                            .fill(Color(.separatorColor))
                            .frame(height: 0.5)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func sectionRow(for level: RatingLevel) -> some View {
        let criteria = session.criterionScores.filter { $0.ratingLevel == level }
        let score = ScoringEngine.sectionScore(criteria: criteria)
        let threshold = level.defaultPassingThreshold
        let total = criteria.count
        let achieved = criteria.reduce(0.0) { $0 + ($1.mark?.rawValue ?? 0) }

        let badge: BadgeState = {
            guard let s = score else { return .pending }
            return s >= threshold ? .pass : .fail
        }()

        return HStack(spacing: 0) {
            tableCell(level.displayName, width: 160)
            tableCell(
                score != nil ? String(format: "%.1f / %d", achieved, total) : "–",
                width: 80
            )
            tableCell(
                score != nil ? String(format: "%.0f%%", score! * 100) : "–",
                width: 70
            )
            tableCell(String(format: "%.0f%%", threshold * 100), width: 90)
            HStack {
                ScoreBadge(state: badge, customLabel: score == nil ? "–" : (score! >= threshold ? "Pass" : "Fail"))
                Spacer()
            }
            .frame(width: 80)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private func tableCell(_ text: String, width: CGFloat, isHeader: Bool = false) -> some View {
        Text(text)
            .font(.system(size: isHeader ? 11 : 13, weight: isHeader ? .medium : .regular))
            .foregroundStyle(isHeader ? Color(.secondaryLabelColor) : Color(.labelColor))
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, isHeader ? 6 : 8)
    }

    // MARK: - Extra points

    private var extraPointsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extra Points")
                .font(.system(size: 15, weight: .medium))

            if session.extraEntries.isEmpty {
                Text("No extra point entries.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabelColor))
            } else {
                VStack(spacing: 2) {
                    ForEach(session.extraEntries.sorted { $0.createdAt < $1.createdAt }) { entry in
                        HStack {
                            Text(entry.note)
                                .font(.system(size: 13))
                                .italic()
                            Spacer()
                            Text(entry.value >= 0
                                 ? String(format: "+%.1f", entry.value)
                                 : String(format: "%.1f", entry.value))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(entry.value > 0 ? Color(hex: "#27500A") : Color(hex: "#791F1F"))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - Final score block

    private var finalScoreBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Final Score")
                .font(.system(size: 15, weight: .medium))

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if let score = vm.finalScore {
                    Text(String(format: "%.1f%%", min(max(score, 0), 100)))
                        .font(.system(size: 28, weight: .medium))
                } else {
                    Text("–")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let passed = vm.overallPassed {
                        ScoreBadge(state: passed ? .pass : .fail)
                    } else {
                        ScoreBadge(state: .pending)
                    }

                    let delta = vm.extraDelta
                    if delta != 0 {
                        Text(delta >= 0
                             ? String(format: "Extra: +%.1f%%", delta)
                             : String(format: "Extra: %.1f%%", delta))
                            .font(.system(size: 11))
                            .foregroundStyle(delta > 0 ? Color(hex: "#27500A") : Color(hex: "#791F1F"))
                    }
                }
            }

            Text("Threshold: \(String(format: "%.0f%%", finalThreshold))")
                .font(.system(size: 12))
                .foregroundStyle(Color(.secondaryLabelColor))

            // Failure reasons
            failureReasons
        }
        .padding(14)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var failureReasons: some View {
        let reasons = computeFailureReasons()
        if !reasons.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(reasons, id: \.self) { reason in
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#791F1F"))
                        Text(reason)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#791F1F"))
                    }
                }
            }
        }
    }

    private func computeFailureReasons() -> [String] {
        var reasons: [String] = []
        for level in session.targetRating.requiredLevels {
            let criteria = session.criterionScores.filter { $0.ratingLevel == level }
            if let score = ScoringEngine.sectionScore(criteria: criteria) {
                let threshold = level.defaultPassingThreshold
                if score < threshold {
                    reasons.append("\(level.displayName) did not meet \(String(format: "%.0f%%", threshold * 100)) threshold (scored \(String(format: "%.0f%%", score * 100))).")
                }
            }
        }
        if let final = vm.finalScore, final < finalThreshold {
            reasons.append("Final score \(String(format: "%.1f%%", final)) is below the \(String(format: "%.0f%%", finalThreshold)) passing threshold.")
        }
        return reasons
    }

    // MARK: - Complete button

    private var completeButton: some View {
        HStack {
            Spacer()
            if session.isComplete {
                Label("Marked as Complete", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#27500A"))
                Button("Reopen") {
                    session.isComplete = false
                    vm.touch(context: context)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Button("Mark as Complete") {
                    session.isComplete = true
                    vm.touch(context: context)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
