import SwiftUI
import SwiftData

struct NewSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var candidateName = ""
    @State private var icao = ""
    @State private var examinerName = ""
    @State private var targetRating: RatingLevel = .s1

    private var isValid: Bool {
        !candidateName.trimmingCharacters(in: .whitespaces).isEmpty &&
        icao.count >= 2 &&
        !examinerName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New Examination Session")
                .font(.system(size: 15, weight: .medium))
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 14) {
                fieldRow(label: "Candidate") {
                    TextField("@Username", text: $candidateName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { normalizeCandidateName() }
                }

                fieldRow(label: "ICAO") {
                    TextField("EDDF", text: $icao)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: icao) { _, newValue in
                            let normalized = String(newValue.uppercased().prefix(4))
                            if icao != normalized { icao = normalized }
                        }
                }

                fieldRow(label: "Examiner") {
                    TextField("Your initials or name", text: $examinerName)
                        .textFieldStyle(.roundedBorder)
                }

                fieldRow(label: "Target Rating") {
                    Picker("", selection: $targetRating) {
                        ForEach(RatingLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Text("Examining for \(targetRating.rawValue) will include \(targetRating.scopeDescription)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.secondaryLabelColor))
                    .padding(.leading, 100)
            }

            Spacer().frame(height: 24)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Create Session") { createSession() }
                    .keyboardShortcut(.return, modifiers: [])
                    .disabled(!isValid)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    @ViewBuilder
    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(.secondaryLabelColor))
                .frame(width: 88, alignment: .trailing)
            content()
        }
    }

    private func normalizeCandidateName() {
        var name = candidateName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty && !name.hasPrefix("@") {
            name = "@" + name
        }
        candidateName = name
    }

    private func createSession() {
        normalizeCandidateName()
        let name = candidateName.trimmingCharacters(in: .whitespaces)
        let examiner = examinerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !examiner.isEmpty, icao.count >= 2 else { return }

        let session = Session(
            candidateName: name,
            icao: icao.uppercased(),
            examinerName: examiner,
            targetRating: targetRating
        )
        context.insert(session)

        for level in targetRating.requiredLevels {
            let scores = ExamTemplate.criterionScores(for: level, from: context)
            for score in scores {
                context.insert(score)
                session.criterionScores.append(score)
            }
        }

        try? context.save()
        dismiss()
    }
}
