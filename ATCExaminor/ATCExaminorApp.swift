import SwiftUI
import SwiftData

@main
struct ATCExaminorApp: App {
    let container: ModelContainer
    @AppStorage("appAppearance") private var appAppearance = "system"

    init() {
        do {
            container = try ModelContainer(for: Session.self, CriterionScore.self, ExtraEntry.self, ExamSection.self, CriterionGroup.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onAppear {
                    ExamTemplate.seedIfNeeded(context: container.mainContext)
                    if UserDefaults.standard.object(forKey: "discordRPCEnabled") as? Bool ?? true {
                        DiscordRichPresence.shared.start()
                    }
                    applyAppAppearance(appAppearance)
                }
                .onDisappear {
                    DiscordRichPresence.shared.stop()
                }
                .onChange(of: appAppearance) { _, newValue in
                    applyAppAppearance(newValue)
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 780)
        .commands {
            DiscordRPCCommands()
            AppearanceCommands()
        }

        Settings {
            SettingsView()
                .modelContainer(container)
        }
    }
}
