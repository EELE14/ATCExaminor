import SwiftUI

struct BottomScoreBar: View {
    let vm: SessionViewModel

    private var finalThreshold: Double {
        UserDefaults.standard.double(forKey: "finalPassingThreshold").nonZeroOr(84.0)
    }

    private var progressColor: Color {
        guard let score = vm.finalScore else { return Color(.systemOrange) }
        if score >= finalThreshold { return Color(hex: "#27500A") }
        if score >= finalThreshold - 5 { return Color(hex: "#633806") }
        return Color(hex: "#791F1F")
    }

    private var progressBackground: Color {
        guard let score = vm.finalScore else { return Color(hex: "#FAEEDA") }
        if score >= finalThreshold { return Color(hex: "#EAF3DE") }
        if score >= finalThreshold - 5 { return Color(hex: "#FAEEDA") }
        return Color(hex: "#FCEBEB")
    }

    var body: some View {
        HStack(spacing: 16) {
            // Current section score
            VStack(alignment: .leading, spacing: 1) {
                Text("SECTION")
                    .font(.system(size: 9, weight: .medium))
                    .kerning(0.5)
                    .foregroundStyle(Color(.tertiaryLabelColor))
                if let score = vm.currentSectionScore {
                    Text(String(format: "%.0f%%", score * 100))
                        .font(.system(size: 13, weight: .medium))
                } else {
                    Text("–")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                }
            }

            Rectangle()
                .fill(Color(.separatorColor))
                .frame(width: 0.5, height: 28)

            // Extra delta
            VStack(alignment: .leading, spacing: 1) {
                Text("EXTRA")
                    .font(.system(size: 9, weight: .medium))
                    .kerning(0.5)
                    .foregroundStyle(Color(.tertiaryLabelColor))
                let delta = vm.extraDelta
                Text(delta == 0 ? "–" : String(format: "%+.1f%%", delta))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(delta > 0 ? Color(hex: "#27500A") : delta < 0 ? Color(hex: "#791F1F") : Color(.secondaryLabelColor))
            }


            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressBackground)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geo.size.width * vm.progressFraction)
                        .animation(.easeInOut(duration: 0.25), value: vm.progressFraction)
                    // Threshold tick
                    Rectangle()
                        .fill(Color(.secondaryLabelColor).opacity(0.55))
                        .frame(width: 1.5)
                        .offset(x: geo.size.width * (finalThreshold / 100) - 0.75)
                }
            }
            .frame(height: 5)

            // Overall badge
            Group {
                switch vm.overallPassed {
                case true:
                    ScoreBadge(state: .pass)
                case false:
                    ScoreBadge(state: .fail)
                case nil:
                    ScoreBadge(state: .inProgress, customLabel: "In Progress")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.windowBackgroundColor))
    }
}
