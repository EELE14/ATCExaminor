import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ExaminationCriteriaSettings()
                .tabItem { Label("Examination Criteria", systemImage: "list.clipboard") }

            DiscordExportSettings()
                .tabItem { Label("Discord & Export", systemImage: "paperplane") }
        }
        .frame(width: 640, height: 560)
    }
}
