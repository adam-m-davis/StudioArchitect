import SwiftUI

enum SidebarItem: String, Hashable, CaseIterable {
    case sessions = "Sessions"
    case clients = "Clients"
    case team = "Team"

    var icon: String {
        switch self {
        case .sessions: return "photo.stack"
        case .clients: return "person.2"
        case .team: return "person.badge.shield.checkmark"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .sessions

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("Studio Architect")
        } detail: {
            switch selection {
            case .sessions, nil:
                HubView()
            case .clients:
                ClientsView()
            case .team:
                TeamView()
            }
        }
    }
}
