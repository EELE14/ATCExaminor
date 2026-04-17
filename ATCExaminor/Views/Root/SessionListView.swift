import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.lastModified, order: .reverse) private var sessions: [Session]

    @Binding var selectedSession: Session?
    @State private var showNewSession = false
    @State private var sessionToDelete: Session? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        List(selection: $selectedSession) {
            ForEach(sessions) { session in
                SessionRow(session: session)
                    .tag(session)
                    .contextMenu {
                        Button(role: .destructive) {
                            sessionToDelete = session
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Session", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    sessionToDelete = sessions[index]
                    showDeleteConfirmation = true
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewSession = true
                } label: {
                    Label("New Session", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewSession) {
            NewSessionSheet()
        }
        .alert("Delete Session?", isPresented: $showDeleteConfirmation, presenting: sessionToDelete) { session in
            Button("Delete", role: .destructive) {
                if selectedSession?.id == session.id {
                    selectedSession = nil
                }
                DispatchQueue.main.async {
                    context.delete(session)
                    try? context.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { session in
            Text("This will permanently delete the session for \(session.candidateName). This cannot be undone.")
        }
    }
}

private struct SessionRow: View {
    let session: Session

    private var resultBadge: BadgeState {
        guard session.isComplete else { return .inProgress }
        let passed = ScoringEngine.overallPassed(
            session: session,
            finalThreshold: UserDefaults.standard.double(forKey: "finalPassingThreshold").nonZeroOr(84.0)
        )
        switch passed {
        case true:  return .pass
        case false: return .fail
        case nil:   return .inProgress
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.candidateName)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                ScoreBadge(state: resultBadge)
            }
            HStack(spacing: 6) {
                Text(session.icao)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.secondaryLabelColor))
                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.tertiaryLabelColor))
                Text(session.targetRating.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabelColor))
                Spacer()
                Text(session.lastModified.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.tertiaryLabelColor))
            }
        }
        .padding(.vertical, 2)
    }
}

extension Double {
    func nonZeroOr(_ fallback: Double) -> Double {
        self == 0 ? fallback : self
    }
}
