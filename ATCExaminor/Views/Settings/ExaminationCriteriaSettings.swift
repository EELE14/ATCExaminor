import SwiftUI
import SwiftData

struct ExaminationCriteriaSettings: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ExamSection.orderIndex) private var sections: [ExamSection]

    @State private var sectionToReset: ExamSection? = nil
    @State private var showResetSectionAlert = false
    @State private var showResetAllAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(sections) { section in
                    SectionEditor(section: section, onChanged: { save() })
                }

                Divider()

                HStack {
                    Spacer()
                    Button("Reset All Sections to Defaults") {
                        showResetAllAlert = true
                    }
                    .foregroundStyle(Color(.systemRed))
                }
            }
            .padding(16)
        }
        .alert("Reset All Sections?", isPresented: $showResetAllAlert) {
            Button("Reset", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore all examination criteria and thresholds to their defaults. Existing sessions are not affected.")
        }
    }

    private func save() {
        try? context.save()
    }

    private func resetAll() {
        for section in sections {
            resetSection(section)
        }
        save()
    }

    private func resetSection(_ section: ExamSection) {
        guard let seed = ExamTemplate.sections.first(where: { $0.level == section.level }) else { return }
        section.displayName = seed.displayName
        section.passingThreshold = seed.passingThreshold

        for group in section.groups { context.delete(group) }
        section.groups = []

        for (i, g) in seed.groups.enumerated() {
            let group = CriterionGroup(label: g.label, orderIndex: i, criteria: g.criteria)
            context.insert(group)
            section.groups.append(group)
        }
    }
}

private struct SectionEditor: View {
    @Bindable var section: ExamSection
    let onChanged: () -> Void

    @State private var expanded = true
    @State private var showResetAlert = false
    @Environment(\.modelContext) private var context

    private var thresholdText: String {
        String(format: "%.0f", section.passingThreshold * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header row
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                        .frame(width: 16)
                }
                .buttonStyle(.plain)

                TextField("Section name", text: $section.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .textFieldStyle(.plain)
                    .onChange(of: section.displayName) { _, _ in onChanged() }

                Text("Threshold:")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(.secondaryLabelColor))

                ThresholdField(threshold: $section.passingThreshold, onChanged: onChanged)

                Button("Reset to Defaults") {
                    showResetAlert = true
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(.systemRed))
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(section.groups.sorted { $0.orderIndex < $1.orderIndex }) { group in
                        GroupEditor(group: group, onChanged: onChanged)
                    }

                    Button {
                        addGroup()
                    } label: {
                        Label("Add Group", systemImage: "plus")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(.systemBlue))
                    .padding(.leading, 8)
                }
                .padding(.top, 8)
                .padding(.leading, 16)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        .alert("Reset Section?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { resetSection() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore \(section.displayName) criteria and threshold to defaults. Existing sessions are not affected.")
        }
    }

    private func addGroup() {
        let idx = (section.groups.map { $0.orderIndex }.max() ?? -1) + 1
        let group = CriterionGroup(label: "", orderIndex: idx)
        context.insert(group)
        section.groups.append(group)
        onChanged()
    }

    private func resetSection() {
        guard let seed = ExamTemplate.sections.first(where: { $0.level == section.level }) else { return }
        section.displayName = seed.displayName
        section.passingThreshold = seed.passingThreshold
        for group in section.groups { context.delete(group) }
        section.groups = []
        for (i, g) in seed.groups.enumerated() {
            let group = CriterionGroup(label: g.label, orderIndex: i, criteria: g.criteria)
            context.insert(group)
            section.groups.append(group)
        }
        onChanged()
    }
}

private struct GroupEditor: View {
    @Bindable var group: CriterionGroup
    let onChanged: () -> Void
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Group label (leave blank for flat section)", text: $group.label)
                    .font(.system(size: 11, weight: .medium))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color(.secondaryLabelColor))
                    .onChange(of: group.label) { _, _ in onChanged() }
            }

            List {
                ForEach(Array(group.criteria.enumerated()), id: \.offset) { index, _ in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(Color(.tertiaryLabelColor))
                            .font(.system(size: 11))

                        TextField("Criterion text", text: Binding(
                            get: { index < group.criteria.count ? group.criteria[index] : "" },
                            set: { if index < group.criteria.count { group.criteria[index] = $0; onChanged() } }
                        ))
                        .font(.system(size: 12))
                        .textFieldStyle(.plain)

                        Button {
                            if index < group.criteria.count {
                                group.criteria.remove(at: index)
                                onChanged()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(Color(.systemRed))
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onMove { from, to in
                    group.criteria.move(fromOffsets: from, toOffset: to)
                    onChanged()
                }
            }
            .listStyle(.plain)
            .frame(height: CGFloat(group.criteria.count) * 28 + 4)

            Button {
                group.criteria.append("")
                onChanged()
            } label: {
                Label("Add Criterion", systemImage: "plus")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(.systemBlue))
        }
        .padding(8)
        .background(Color(.windowBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }
}

private struct ThresholdField: View {
    @Binding var threshold: Double
    let onChanged: () -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 2) {
            TextField("80", text: $text)
                .font(.system(size: 12))
                .frame(width: 36)
                .multilineTextAlignment(.trailing)
                .focused($focused)
                .onAppear { text = String(format: "%.0f", threshold * 100) }
                .onChange(of: threshold) { _, newThreshold in
                    if !focused { text = String(format: "%.0f", newThreshold * 100) }
                }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { commit() }
                }
                .onSubmit { commit() }
            Text("%")
                .font(.system(size: 12))
                .foregroundStyle(Color(.secondaryLabelColor))
        }

    }

    private func commit() {
        if let value = Double(text), value >= 1, value <= 100 {
            threshold = value / 100.0
            onChanged()
        } else {
            text = String(format: "%.0f", threshold * 100)
        }
    }
}
