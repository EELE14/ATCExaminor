import SwiftUI

struct SessionDetailView: View {
    let session: Session
    @State private var vm: SessionViewModel
    @State private var sessionOpenedAt = Date()
    @State private var showQuickObservation = false

    init(session: Session) {
        self.session = session
        self._vm = State(initialValue: SessionViewModel(session: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                SectionNavigator(vm: vm)
                    .frame(minWidth: 80, idealWidth: 220, maxWidth: 340)

                ZStack {
                    SectionScoringView(session: session, vm: vm, upToLevel: vm.activeSectionLevel)
                        .opacity(vm.selectedPanel.isSection ? 1 : 0)
                        .allowsHitTesting(vm.selectedPanel.isSection)

                    ExtraPointsView(session: session, vm: vm, isReadOnly: session.isComplete)
                        .padding(16)
                        .background(Color(.windowBackgroundColor))
                        .opacity(vm.selectedPanel == .extraPoints ? 1 : 0)
                        .allowsHitTesting(vm.selectedPanel == .extraPoints)

                    FinalSummaryView(session: session, vm: vm)
                        .padding(16)
                        .background(Color(.windowBackgroundColor))
                        .opacity(vm.selectedPanel == .finalSummary ? 1 : 0)
                        .allowsHitTesting(vm.selectedPanel == .finalSummary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 300)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            BottomScoreBar(vm: vm)
        }
        .onAppear {
            sessionOpenedAt = Date()
            pushPresence()
        }
        .onDisappear {
            DiscordRichPresence.shared.clear()
        }
        .onChange(of: vm.selectedPanel) { _, _ in
            pushPresence()
        }
        // ⌘O — quick observation entry
        .background {
            Button("") { showQuickObservation = true }
                .keyboardShortcut("o", modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
        }
        .sheet(isPresented: $showQuickObservation) {
            QuickObservationSheet(session: session, isPresented: $showQuickObservation)
        }
    }

    private func pushPresence() {
        let showName = UserDefaults.standard.object(forKey: "discordRPCShowName") as? Bool ?? true
        let showICAO = UserDefaults.standard.object(forKey: "discordRPCShowICAO") as? Bool ?? true

        var parts: [String] = []
        if showName { parts.append(session.candidateName) }
        if showICAO { parts.append(session.icao) }
        let details = parts.isEmpty ? "Examination in progress" : parts.joined(separator: " · ")

        let state: String = {
            switch vm.selectedPanel {
            case .section(let level): return "\(level.rawValue) – \(level.sectionTitle)"
            case .extraPoints:        return "Extra Points"
            case .finalSummary:       return "Final Summary"
            }
        }()

        DiscordRichPresence.shared.update(details: details, state: state, since: sessionOpenedAt)
    }
}
