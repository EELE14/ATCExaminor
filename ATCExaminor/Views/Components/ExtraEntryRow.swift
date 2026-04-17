import SwiftUI
import SwiftData

struct ExtraEntryRow: View {
    @Bindable var entry: ExtraEntry
    @Environment(\.modelContext) private var context
    let onChanged: () -> Void
    var isReadOnly: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.note)
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(Color(.labelColor))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Value stepper
            HStack(spacing: 4) {
                if !isReadOnly {
                    Button {
                        entry.value = max(-5.0, (entry.value * 10 - 5).rounded() / 10)
                        save()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                Text(entry.value >= 0
                     ? String(format: "+%.1f", entry.value)
                     : String(format: "%.1f", entry.value))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(entry.value > 0 ? Color(hex: "#27500A") : entry.value < 0 ? Color(hex: "#791F1F") : Color(.secondaryLabelColor))
                    .frame(width: 40, alignment: .center)
                    .monospacedDigit()

                if !isReadOnly {
                    Button {
                        entry.value = min(5.0, (entry.value * 10 + 5).rounded() / 10)
                        save()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            if !isReadOnly {
                Button {
                    context.delete(entry)
                    try? context.save()
                    onChanged()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func save() {
        try? context.save()
        onChanged()
    }
}
