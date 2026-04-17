import SwiftUI
import AppKit

struct AppearanceCommands: Commands {
    @AppStorage("appAppearance") var appAppearance = "system"

    var body: some Commands {
        CommandMenu("View") {
            Toggle("System Appearance", isOn: Binding(
                get: { appAppearance == "system" },
                set: { if $0 { appAppearance = "system" } }
            ))
            Toggle("Light Mode", isOn: Binding(
                get: { appAppearance == "light" },
                set: { if $0 { appAppearance = "light" } }
            ))
            Toggle("Dark Mode", isOn: Binding(
                get: { appAppearance == "dark" },
                set: { if $0 { appAppearance = "dark" } }
            ))
        }
    }
}

func applyAppAppearance(_ value: String) {
    switch value {
    case "light":  NSApp.appearance = NSAppearance(named: .aqua)
    case "dark":   NSApp.appearance = NSAppearance(named: .darkAqua)
    default:       NSApp.appearance = nil
    }
}
