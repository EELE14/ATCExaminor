import SwiftUI

enum BadgeState {
    case pass
    case fail
    case warning
    case inProgress
    case pending

    var background: Color {
        switch self {
        case .pass:       return Color(hex: "#EAF3DE")
        case .fail:       return Color(hex: "#FCEBEB")
        case .warning:    return Color(hex: "#FAEEDA")
        case .inProgress: return Color(.quaternaryLabelColor)
        case .pending:    return Color(.quaternaryLabelColor)
        }
    }

    var foreground: Color {
        switch self {
        case .pass:       return Color(hex: "#27500A")
        case .fail:       return Color(hex: "#791F1F")
        case .warning:    return Color(hex: "#633806")
        case .inProgress: return Color(.secondaryLabelColor)
        case .pending:    return Color(.secondaryLabelColor)
        }
    }

    var label: String {
        switch self {
        case .pass:       return "Pass"
        case .fail:       return "Fail"
        case .warning:    return "Below Threshold"
        case .inProgress: return "In Progress"
        case .pending:    return "–"
        }
    }
}

struct ScoreBadge: View {
    let state: BadgeState
    var customLabel: String? = nil

    var body: some View {
        Text(customLabel ?? state.label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(state.foreground)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(state.background, in: RoundedRectangle(cornerRadius: 5))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
