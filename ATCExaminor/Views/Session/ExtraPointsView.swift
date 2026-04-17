import SwiftUI
import SwiftData

struct ExtraPointsView: View {
    let session: Session
    let vm: SessionViewModel
    var isReadOnly: Bool = false
    @Environment(\.modelContext) private var context

    @State private var newNote = ""
    @State private var newValue: Double = -1.0

    private var sortedEntries: [ExtraEntry] {
        session.extraEntries.sorted { $0.createdAt < $1.createdAt }
    }

    private var netDelta: Double {
        ScoringEngine.extraDelta(session: session)
    }

    private var totalCriteria: Int {
        session.criterionScores.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Points")
                .font(.system(size: 15, weight: .medium))

            if sortedEntries.isEmpty {
                Text("No extra point entries yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabelColor))
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedEntries) { entry in
                        ExtraEntryRow(entry: entry, onChanged: {
                            vm.touch(context: context)
                        }, isReadOnly: isReadOnly)
                        if entry.id != sortedEntries.last?.id {
                            Rectangle()
                                .fill(Color(.separatorColor))
                                .frame(height: 0.5)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
            }

            // Add new entry row
            if !isReadOnly {
                HStack(spacing: 8) {
                    TextField("Add observation...", text: $newNote)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 4) {
                        Button {
                            newValue = max(-5.0, newValue - 0.5)
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 11))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text(newValue >= 0
                             ? String(format: "+%.1f", newValue)
                             : String(format: "%.1f", newValue))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(newValue > 0 ? Color(hex: "#27500A") : newValue < 0 ? Color(hex: "#791F1F") : Color(.secondaryLabelColor))
                            .frame(width: 44, alignment: .center)

                        Button {
                            newValue = min(5.0, newValue + 0.5)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button("Add") {
                        addEntry()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(newNote.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Net delta summary
            if !session.extraEntries.isEmpty {
                let rawNet = session.extraEntries.reduce(0.0) { $0 + $1.value }
                HStack(spacing: 4) {
                    Text("Net extra:")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    Text(rawNet >= 0
                         ? String(format: "+%.1f pts", rawNet)
                         : String(format: "%.1f pts", rawNet))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(rawNet > 0 ? Color(hex: "#27500A") : rawNet < 0 ? Color(hex: "#791F1F") : Color(.secondaryLabelColor))
                    Text("across \(totalCriteria) criteria →")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    Text(netDelta >= 0
                         ? String(format: "+%.1f%%", netDelta)
                         : String(format: "%.1f%%", netDelta))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(netDelta > 0 ? Color(hex: "#27500A") : netDelta < 0 ? Color(hex: "#791F1F") : Color(.secondaryLabelColor))
                }
            }
        }
    }

    private func addEntry() {
        let note = newNote.trimmingCharacters(in: .whitespaces)
        guard !note.isEmpty else { return }
        let entry = ExtraEntry(note: note, value: newValue)
        session.extraEntries.append(entry)
        vm.touch(context: context)
        newNote = ""
        newValue = -1.0
    }
}
