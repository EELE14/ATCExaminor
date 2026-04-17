import SwiftUI
import SwiftData

struct CriterionRow: View {
    @Bindable var criterion: CriterionScore
    @Environment(\.modelContext) private var context
    let onChanged: () -> Void
    var isReadOnly: Bool = false

    @State private var noteExpanded = false
    @State private var showNotePopover = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(criterion.criterionText)
                    .font(.system(size: 13))
                    .foregroundStyle(isReadOnly ? Color(.secondaryLabelColor) : Color(.labelColor))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !criterion.note.isEmpty else { return }
                        showNotePopover = true
                    }
                    .popover(isPresented: $showNotePopover, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Note")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(.secondaryLabelColor))
                            Text(criterion.note)
                                .font(.system(size: 13))
                                .fixedSize(horizontal: false, vertical: true)
                            if !isReadOnly {
                                Button("Edit Note") {
                                    showNotePopover = false
                                    noteExpanded = true
                                    noteFocused = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(12)
                        .frame(minWidth: 200, maxWidth: 300)
                    }

                MarkSelector(mark: $criterion.mark) {
                    touch()
                }
                .disabled(isReadOnly)
                .opacity(isReadOnly ? 0.45 : 1)

                noteButton
                    .disabled(isReadOnly)
                    .opacity(isReadOnly ? 0.45 : 1)
            }
            .padding(.vertical, 6)

            if noteExpanded {
                TextField("Note...", text: $criterion.note, axis: .vertical)
                    .font(.system(size: 12))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
                    .padding(.bottom, 6)
                    .focused($noteFocused)
                    .onChange(of: criterion.note) { _, _ in touch() }
                    .onSubmit { collapseNote() }
            }
        }
        .onChange(of: noteFocused) { _, focused in
            if !focused { collapseNote() }
        }
    }

    private var noteButton: some View {
        Button {
            noteExpanded.toggle()
            if noteExpanded {
                noteFocused = true
            }
        } label: {
            Image(systemName: "pencil")
                .font(.system(size: 12))
                .foregroundStyle(criterion.note.isEmpty ? Color(.tertiaryLabelColor) : Color(hex: "#185FA5"))
                .frame(width: 24, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            criterion.note.isEmpty ? Color(.separatorColor) : Color(hex: "#185FA5"),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func collapseNote() {
        noteExpanded = false
        noteFocused = false
    }

    private func touch() {
        onChanged()
    }
}
