import SwiftUI
import SwiftData

struct QuickObservationSheet: View {
    let session: Session
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Observation")
                    .font(.system(size: 15, weight: .semibold))
                Text("Saved as ±0 pts — set the value later in Extra Points.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))
            }

            TextField("Observation note...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(3...5)
                .padding(8)
                .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 0.5))
                .focused($focused)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                Button("Add Observation") { submit() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear { focused = true }
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = ExtraEntry(note: trimmed, value: 0.0)
        session.extraEntries.append(entry)
        try? context.save()
        isPresented = false
    }
}
