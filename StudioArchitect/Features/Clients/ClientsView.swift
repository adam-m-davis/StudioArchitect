import SwiftUI
import GRDB

struct ClientsView: View {
    @Environment(\.appDatabase) var db
    @State private var clients: [Client] = []

    var body: some View {
        Group {
            if clients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)
                    Text("No Clients Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Button("Add Client") {}
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(clients) { client in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(client.name)
                            .font(.headline)
                        Text(client.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Label("Add Client", systemImage: "plus")
                }
            }
        }
        .task {
            await loadClients()
        }
    }

    private func loadClients() async {
        do {
            clients = try await db.dbQueue.read { db in
                try Client.order(Column("name")).fetchAll(db)
            }
        } catch {
            print("Failed to load clients: \(error)")
        }
    }
}
