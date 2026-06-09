import Foundation
import GRDB

struct Session: Identifiable, Sendable {
    var id: String
    var clientId: String
    var name: String
    var type: SessionType
    var shootDate: Date
    var location: String?
    var currentStage: SessionStage
    var sourcePath: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        clientId: String,
        name: String,
        type: SessionType = .portrait,
        shootDate: Date = .now,
        location: String? = nil,
        currentStage: SessionStage = .imported,
        sourcePath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.clientId = clientId
        self.name = name
        self.type = type
        self.shootDate = shootDate
        self.location = location
        self.currentStage = currentStage
        self.sourcePath = sourcePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum SessionType: String, Codable, Sendable, CaseIterable {
        case wedding
        case portrait
        case event
        case corporate
        case family
        case newborn
        case commercial
        case other

        var displayName: String { rawValue.capitalized }
    }

    enum SessionStage: String, Codable, Sendable, CaseIterable {
        case imported
        case culled
        case firstPass = "first_pass"
        case editing
        case exported
        case delivered
        case archived

        var displayName: String {
            switch self {
            case .imported: return "Imported"
            case .culled: return "Culled"
            case .firstPass: return "First Pass"
            case .editing: return "Editing"
            case .exported: return "Exported"
            case .delivered: return "Delivered"
            case .archived: return "Archived"
            }
        }

        var stepIndex: Int {
            switch self {
            case .imported: return 0
            case .culled: return 1
            case .firstPass: return 2
            case .editing: return 3
            case .exported: return 4
            case .delivered: return 5
            case .archived: return 6
            }
        }
    }
}

extension Session: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        clientId = row["client_id"]
        name = row["name"]
        type = SessionType(rawValue: row["type"] as String) ?? .portrait
        shootDate = row["shoot_date"]
        location = row["location"]
        currentStage = SessionStage(rawValue: row["current_stage"] as String) ?? .imported
        sourcePath = row["source_path"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }
}

extension Session: PersistableRecord {
    static let databaseTableName = "sessions"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["client_id"] = clientId
        container["name"] = name
        container["type"] = type.rawValue
        container["shoot_date"] = shootDate
        container["location"] = location
        container["current_stage"] = currentStage.rawValue
        container["source_path"] = sourcePath
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }
}
