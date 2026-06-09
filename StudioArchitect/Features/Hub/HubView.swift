import SwiftUI
import GRDB

struct HubView: View {
    @Environment(\.appDatabase) var db
    @State private var sessions: [Session] = []

    var body: some View {
        Group {
            if sessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Label("New Session", systemImage: "plus")
                }
            }
        }
        .task {
            await loadSessions()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Import your first shoot to get started.")
                .foregroundStyle(.secondary)
            Button("New Session") {}
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionList: some View {
        List(sessions) { session in
            SessionRowView(session: session)
        }
    }

    private func loadSessions() async {
        do {
            sessions = try await db.dbQueue.read { db in
                try Session.order(Column("shoot_date").desc).fetchAll(db)
            }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
}
