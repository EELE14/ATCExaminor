import SwiftUI

struct DiscordExportSettings: View {
    @AppStorage("discordWebhookURL") private var webhookURL = ""
    @AppStorage("finalPassingThreshold") private var finalThresholdStored: Double = 0
    @AppStorage("discordReportTemplate") private var mainTemplate = ""
    @AppStorage("sectionBlockTemplate") private var sectionTemplate = ""
    @AppStorage("groupBlockTemplate") private var groupTemplate = ""
    @AppStorage("markSymbolFull") private var markFull = ""
    @AppStorage("markSymbolHalf") private var markHalf = ""
    @AppStorage("markSymbolNone") private var markNone = ""

    @State private var testWebhookStatus: TestStatus = .idle
    @State private var showResetTemplateAlert = false
    @State private var finalThresholdText = ""

    enum TestStatus {
        case idle, testing, success, failure(String)
    }

    private var effectiveFinalThreshold: Double {
        finalThresholdStored == 0 ? 84.0 : finalThresholdStored
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                webhookSection

                Divider()

                finalThresholdSection

                Divider()

                templateSection

                Divider()

                markSymbolsSection
            }
            .padding(16)
        }
        .onAppear { loadDefaults() }
    }

    // MARK: - Sections

    private var webhookSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discord Webhook")
                .font(.system(size: 13, weight: .medium))

            HStack {
                TextField("https://discord.com/api/webhooks/...", text: $webhookURL)
                    .textFieldStyle(.roundedBorder)

                Button("Test") { testWebhook() }
                    .disabled(webhookURL.isEmpty || testWebhookStatus == .testing)
                    .buttonStyle(.bordered)

                switch testWebhookStatus {
                case .idle: EmptyView()
                case .testing:
                    ProgressView().controlSize(.small)
                case .success:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#27500A"))
                case .failure(let msg):
                    Label(msg, systemImage: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#791F1F"))
                        .lineLimit(1)
                }
            }
        }
    }

    private var finalThresholdSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Final Score Passing Threshold")
                .font(.system(size: 13, weight: .medium))

            HStack(spacing: 4) {
                TextField("84", text: $finalThresholdText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onSubmit { commitFinalThreshold() }
                Text("%")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabelColor))
            }
            Text("Used for overall pass/fail calculation across all sections.")
                .font(.system(size: 11))
                .foregroundStyle(Color(.secondaryLabelColor))
        }
    }

    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Report Templates")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Button("Reset to Defaults") {
                    showResetTemplateAlert = true
                }
                .foregroundStyle(Color(.systemRed))
                .font(.system(size: 12))
                .buttonStyle(.plain)
            }
            .alert("Reset Templates?", isPresented: $showResetTemplateAlert) {
                Button("Reset", role: .destructive) { resetTemplates() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore the report templates and mark symbols to their defaults.")
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Main Template")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    TextEditor(text: $mainTemplate)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 0.5))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tokens")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    tokenReference(tokens: [
                        ("{{candidateName}}", "Candidate name"),
                        ("{{sectionBlock:S1}}", "S1 block"),
                        ("{{sectionBlock:S2}}", "S2 block"),
                        ("{{sectionBlock:S3}}", "S3 block"),
                        ("{{sectionBlock:C1}}", "C1 block"),
                        ("{{extraPointsBlock}}", "Extra entries"),
                        ("{{rawScore}}", "Section average %"),
                        ("{{extraDelta}}", "Extra delta %"),
                        ("{{finalScore}}", "Final score %"),
                        ("{{finalThreshold}}", "Passing threshold"),
                        ("{{finalResult}}", "PASS or FAIL"),
                    ])
                }
                .frame(width: 200)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Section Block Template")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    TextEditor(text: $sectionTemplate)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 0.5))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Section Tokens")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    tokenReference(tokens: [
                        ("{{sectionTitle}}", "e.g. S1 – Delivery + Ground"),
                        ("{{groupBlocks}}", "Rendered group blocks"),
                        ("{{totalScore}}", "e.g. 8/10 (80%)"),
                        ("{{passingScore}}", "e.g. 80%"),
                        ("{{sectionResult}}", "PASS or FAIL"),
                    ])
                }
                .frame(width: 200)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Group Block Template")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    TextEditor(text: $groupTemplate)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(minHeight: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 0.5))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Group Tokens")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabelColor))
                    tokenReference(tokens: [
                        ("{{groupLabel}}", "e.g. Delivery"),
                        ("{{criteriaList}}", "One criterion per line"),
                    ])
                }
                .frame(width: 200)
            }
        }
    }

    private var markSymbolsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mark Symbols")
                .font(.system(size: 13, weight: .medium))

            HStack(spacing: 16) {
                markSymbolField(label: "Full Mark", binding: $markFull, placeholder: "✅")
                markSymbolField(label: "Half Mark", binding: $markHalf, placeholder: "🟡")
                markSymbolField(label: "No Mark", binding: $markNone, placeholder: "❌")
            }
        }
    }

    private func markSymbolField(label: String, binding: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color(.secondaryLabelColor))
            TextField(placeholder, text: binding)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
        }
    }

    @ViewBuilder
    private func tokenReference(tokens: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(tokens, id: \.0) { token, desc in
                HStack(alignment: .top, spacing: 4) {
                    Text(token)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(.systemBlue))
                    Text("→ \(desc)")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(.secondaryLabelColor))
                }
            }
        }
        .padding(6)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separatorColor), lineWidth: 0.5))
    }

    // MARK: - Actions

    private func testWebhook() {
        testWebhookStatus = .testing
        Task {
            do {
                try await DiscordExporter.send(report: "ATC Examiner: webhook test ✅", to: webhookURL)
                await MainActor.run { testWebhookStatus = .success }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run { testWebhookStatus = .idle }
            } catch {
                await MainActor.run { testWebhookStatus = .failure(error.localizedDescription) }
            }
        }
    }

    private func commitFinalThreshold() {
        if let value = Double(finalThresholdText), value >= 1, value <= 100 {
            finalThresholdStored = value
        }
    }

    private func loadDefaults() {
        finalThresholdText = String(format: "%.0f", effectiveFinalThreshold)
        if mainTemplate.isEmpty { mainTemplate = DiscordExporter.defaultMainTemplate }
        if sectionTemplate.isEmpty { sectionTemplate = DiscordExporter.defaultSectionTemplate }
        if groupTemplate.isEmpty { groupTemplate = DiscordExporter.defaultGroupTemplate }
        if markFull.isEmpty { markFull = "✅" }
        if markHalf.isEmpty { markHalf = "🟡" }
        if markNone.isEmpty { markNone = "❌" }
    }

    private func resetTemplates() {
        mainTemplate = DiscordExporter.defaultMainTemplate
        sectionTemplate = DiscordExporter.defaultSectionTemplate
        groupTemplate = DiscordExporter.defaultGroupTemplate
        markFull = "✅"
        markHalf = "🟡"
        markNone = "❌"
    }
}

extension DiscordExportSettings.TestStatus: Equatable {
    static func == (lhs: DiscordExportSettings.TestStatus, rhs: DiscordExportSettings.TestStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.testing, .testing), (.success, .success): return true
        default: return false
        }
    }
}
