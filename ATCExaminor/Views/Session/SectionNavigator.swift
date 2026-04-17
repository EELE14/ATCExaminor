import SwiftUI

struct SectionNavigator: View {
    @Bindable var vm: SessionViewModel

    @AppStorage("discordWebhookURL") private var webhookURL = ""
    @State private var showExportIncomplete = false
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showExportSuccess = false
    @State private var isExporting = false
    @State private var exportTask: Task<Void, Never>?
    @State private var currentWidth: CGFloat = 220

    private var isCompact: Bool { currentWidth < 185 }

    var body: some View {
        VStack(spacing: 0) {
            if isCompact {
                compactHeader
            } else {
                headerBlock
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
            }

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(vm.session.targetRating.requiredLevels, id: \.self) { level in
                        if isCompact {
                            compactNavItem(for: level)
                        } else {
                            navItem(for: level)
                        }
                    }

                    Divider().padding(.vertical, 4)

                    if isCompact {
                        compactExtraPointsNavItem
                        compactFinalSummaryNavItem
                    } else {
                        extraPointsNavItem
                        finalSummaryNavItem
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            Spacer(minLength: 0)
            Divider()

            if isCompact {
                compactBottomBlock
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
            } else {
                bottomBlock
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
            }
        }
        .background(Color(.windowBackgroundColor))
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { currentWidth = $0 }
        .overlay(alignment: .bottom) {
            if showExportSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#27500A"))
                    if !isCompact {
                        Text("Exported to Discord")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "#27500A"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "#EAF3DE"), in: RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showExportSuccess)
        .animation(.easeInOut(duration: 0.15), value: isCompact)
        .alert("Incomplete Session", isPresented: $showExportIncomplete) {
            Button("Cancel", role: .cancel) {}
            Button("Export Anyway") { performExport() }
        } message: {
            Text("Not all criteria have been rated. Export anyway?")
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("Copy to Clipboard") { copyToClipboard() }
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage)
        }
    }

    // MARK: - Full Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.session.candidateName)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)

            HStack(spacing: 4) {
                Text(vm.session.icao)
                Text("·")
                Text(vm.session.createdAt.formatted(date: .abbreviated, time: .omitted))
                Text("·")
                Text(vm.session.examinerName)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(.secondaryLabelColor))
            .lineLimit(1)

            ScoreBadge(state: .pending, customLabel: vm.session.targetRating.rawValue)
                .padding(.top, 2)
        }
    }

    // MARK: - Compact Header

    private var compactHeader: some View {
        VStack(spacing: 4) {
            ScoreBadge(state: .pending, customLabel: vm.session.targetRating.rawValue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Full Nav Items

    private func navItem(for level: RatingLevel) -> some View {
        let isSelected = vm.selectedPanel == .section(level)
        let score = vm.sectionScore(for: level)
        let threshold = vm.sectionThreshold(for: level)

        let badge: BadgeState = {
            guard let s = score else { return .pending }
            if s >= threshold { return .pass }
            let allRated = vm.session.criterionScores
                .filter { $0.ratingLevel == level }
                .allSatisfy { $0.mark != nil }
            return allRated ? .fail : .warning
        }()

        let scoreText: String = {
            guard let s = score else { return "–" }
            return String(format: "%.0f%%", s * 100)
        }()

        return Button {
            vm.selectedPanel = .section(level)
        } label: {
            HStack {
                Text(level.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                    .lineLimit(1)
                Spacer()
                if score != nil {
                    Text(scoreText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(badge.foreground)
                } else {
                    Text("–")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(.tertiaryLabelColor))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var extraPointsNavItem: some View {
        let isSelected = vm.selectedPanel == .extraPoints
        let delta = vm.extraDelta
        let deltaText: String = {
            if delta == 0 { return "–" }
            return String(format: "%+.1f%%", delta)
        }()

        return Button {
            vm.selectedPanel = .extraPoints
        } label: {
            HStack {
                Label("Extra Points", systemImage: "plusminus")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                Spacer()
                Text(deltaText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(delta > 0 ? Color(hex: "#27500A") : delta < 0 ? Color(hex: "#791F1F") : Color(.tertiaryLabelColor))
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var finalSummaryNavItem: some View {
        let isSelected = vm.selectedPanel == .finalSummary
        return Button {
            vm.selectedPanel = .finalSummary
        } label: {
            HStack {
                Label("Final Summary", systemImage: "list.clipboard")
                    .font(.system(size: 12))
                    .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compact Nav Items

    private func compactNavItem(for level: RatingLevel) -> some View {
        let isSelected = vm.selectedPanel == .section(level)
        let score = vm.sectionScore(for: level)
        let threshold = vm.sectionThreshold(for: level)

        let badge: BadgeState = {
            guard let s = score else { return .pending }
            if s >= threshold { return .pass }
            let allRated = vm.session.criterionScores
                .filter { $0.ratingLevel == level }
                .allSatisfy { $0.mark != nil }
            return allRated ? .fail : .warning
        }()

        return Button {
            vm.selectedPanel = .section(level)
        } label: {
            HStack(spacing: 4) {
                Text(level.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Circle()
                    .fill(badge.background)
                    .frame(width: 7, height: 7)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var compactExtraPointsNavItem: some View {
        let isSelected = vm.selectedPanel == .extraPoints
        return Button {
            vm.selectedPanel = .extraPoints
        } label: {
            Image(systemName: "plusminus")
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
    }

    private var compactFinalSummaryNavItem: some View {
        let isSelected = vm.selectedPanel == .finalSummary
        return Button {
            vm.selectedPanel = .finalSummary
        } label: {
            Image(systemName: "list.clipboard")
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? Color(.labelColor) : Color(.secondaryLabelColor))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Full Bottom Block

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FINAL SCORE")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(0.5)
                    .foregroundStyle(Color(.secondaryLabelColor))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let score = vm.finalScore {
                        Text(String(format: "%.1f%%", min(max(score, 0), 100)))
                            .font(.system(size: 22, weight: .medium))
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: score)
                    } else {
                        Text("–")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabelColor))
                    }

                    if let passed = vm.overallPassed {
                        ScoreBadge(state: passed ? .pass : .fail)
                    }
                }

                Text("Threshold: \(String(format: "%.0f%%", (UserDefaults.standard.double(forKey: "finalPassingThreshold").nonZeroOr(84.0))))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.tertiaryLabelColor))
            }

            VStack(spacing: 6) {
                Button {
                    handleExport()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text("Export to Discord")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(webhookURL.isEmpty || isExporting)
                .help(webhookURL.isEmpty ? "Configure webhook in Settings first." : "")

                Button("Copy Report") {
                    copyToClipboard()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Compact Bottom Block

    private var compactBottomBlock: some View {
        VStack(spacing: 8) {
            if let score = vm.finalScore {
                Text(String(format: "%.0f%%", min(max(score, 0), 100)))
                    .font(.system(size: 13, weight: .medium))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: score)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("–")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabelColor))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Button {
                handleExport()
            } label: {
                Group {
                    if isExporting {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(webhookURL.isEmpty || isExporting)
            .help(webhookURL.isEmpty ? "Configure webhook in Settings first." : "")
        }
    }

    // MARK: - Export Actions

    private func handleExport() {
        if !vm.allCriteriaRated {
            showExportIncomplete = true
        } else {
            performExport()
        }
    }

    private func performExport() {
        guard !webhookURL.isEmpty else { return }
        exportTask?.cancel()
        isExporting = true
        let report = DiscordExporter.generateReport(session: vm.session)
        let url = webhookURL
        exportTask = Task {
            do {
                try await DiscordExporter.send(report: report, to: url)
                guard !Task.isCancelled else { isExporting = false; return }
                isExporting = false
                showExportSuccess = true
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showExportSuccess = false
            } catch {
                guard !Task.isCancelled else { isExporting = false; return }
                isExporting = false
                exportErrorMessage = error.localizedDescription
                showExportError = true
            }
        }
    }

    private func copyToClipboard() {
        let report = DiscordExporter.generateReport(session: vm.session)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)
    }
}
