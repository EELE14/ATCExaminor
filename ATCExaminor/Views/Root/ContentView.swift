import SwiftUI

struct ContentView: View {
    @State private var selectedSession: Session?
    @AppStorage("discordWebhookURL") private var webhookURL = ""
    @AppStorage("webhookSetupShown") private var webhookSetupShown = false
    @State private var showWebhookSetup = false

    var body: some View {
        NavigationSplitView {
            SessionListView(selectedSession: $selectedSession)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            if let session = selectedSession {
                SessionDetailView(session: session)
                    .id(session.id)
            } else {
                emptyState
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            if !webhookSetupShown && webhookURL.isEmpty {
                showWebhookSetup = true
                webhookSetupShown = true
            }
        }
        .onChange(of: selectedSession) { _, session in
            if session == nil {
                DiscordRichPresence.shared.clear()
            }
        }
        .sheet(isPresented: $showWebhookSetup) {
            WebhookSetupSheet()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(Color(.secondaryLabelColor))
            Text("No Session Selected")
                .font(.system(size: 15, weight: .medium))
            Text("Select a session from the sidebar or create a new one.")
                .font(.system(size: 13))
                .foregroundStyle(Color(.secondaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
