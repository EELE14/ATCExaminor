import SwiftUI

struct MarkSelector: View {
    @Binding var mark: Mark?
    let onChanged: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            markButton("1", value: .full)
            markButton("0.5", value: .half)
            markButton("0", value: .none)
        }
    }

    private func markButton(_ label: String, value: Mark) -> some View {
        let isSelected = mark == value
        return Button(label) {
            if mark == value {
                mark = nil
            } else {
                mark = value
            }
            onChanged()
        }
        .buttonStyle(MarkButtonStyle(isSelected: isSelected, mark: value))
        .frame(width: 52, height: 28)
    }
}

struct MarkButtonStyle: ButtonStyle {
    let isSelected: Bool
    let mark: Mark

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isSelected ? selectedText : Color(.secondaryLabelColor))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? selectedBackground : Color(.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? selectedBorder : Color(.separatorColor), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private var selectedBackground: Color {
        switch mark {
        case .full: return Color(hex: "#EAF3DE")
        case .half: return Color(hex: "#FAEEDA")
        case .none: return Color(hex: "#FCEBEB")
        }
    }

    private var selectedBorder: Color {
        switch mark {
        case .full: return Color(hex: "#97C459")
        case .half: return Color(hex: "#FAC775")
        case .none: return Color(hex: "#F09595")
        }
    }

    private var selectedText: Color {
        switch mark {
        case .full: return Color(hex: "#27500A")
        case .half: return Color(hex: "#633806")
        case .none: return Color(hex: "#791F1F")
        }
    }
}
