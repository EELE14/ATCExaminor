import SwiftUI

struct DiscordRPCCommands: Commands {
    @AppStorage("discordRPCEnabled")   var enabled    = true
    @AppStorage("discordRPCShowName")  var showName   = true
    @AppStorage("discordRPCShowICAO")  var showICAO   = true

    var body: some Commands {
        CommandMenu("Discord") {

            statusItem
            Divider()

            
            Toggle("Enable Rich Presence", isOn: $enabled)
                .onChange(of: enabled) { _, on in
                    if on { DiscordRichPresence.shared.start() }
                    else  { DiscordRichPresence.shared.stop()  }
                }

            Divider()

            Button("Reconnect") {
                DiscordRichPresence.shared.restart()
            }
            .disabled(!enabled)

            Divider()


            Toggle("Show Candidate Name", isOn: $showName)
                .disabled(!enabled)
            Toggle("Show ICAO Code", isOn: $showICAO)
                .disabled(!enabled)
        }
    }

    @ViewBuilder
    private var statusItem: some View {
        let rpc = DiscordRichPresence.shared
        switch rpc.status {
        case .idle:
            Button("● Idle") {}.disabled(true)
        case .connecting:
            Button("◌ Connecting…") {}.disabled(true)
        case .connected:
            Button("● Connected") {}.disabled(true)
        case .failed(let msg):
            Button("✕ \(msg)") {}.disabled(true)
        }
    }
}
