import SwiftUI
import GRDB

struct TeamView: View {
    @Environment(\.appDatabase) var db
    @State private var members: [TeamMember] = []

    var body: some View {
        Group {
            if members.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)
                    Text("No Team Members Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Button("Add Team Member") {}
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(members) { member in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.headline)
                        Text(member.role.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Team")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Label("Add Member", systemImage: "plus")
                }
            }
        }
        .task {
            await loadMembers()
        }
    }

    private func loadMembers() async {
        do {
            members = try await db.dbQueue.read { db in
                try TeamMember.order(Column("name")).fetchAll(db)
            }
        } catch {
            print("Failed to load team members: \(error)")
        }
    }
}
