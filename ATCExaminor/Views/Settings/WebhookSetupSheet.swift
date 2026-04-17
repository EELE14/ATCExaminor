import SwiftUI

struct WebhookSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("discordWebhookURL") private var webhookURL = ""
    @State private var url = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Configure Discord Webhook")
                    .font(.system(size: 15, weight: .medium))
                Text("ATC Examiner exports exam reports to Discord via a webhook. Paste your webhook URL below to get started. You can change this later in Settings.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabelColor))
                    .fixedSize(horizontal: false, vertical: true)
            }

            TextField("https://discord.com/api/webhooks/...", text: $url)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Skip for Now") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") {
                    webhookURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
