import Foundation
import GRDB

struct Client: Identifiable, Sendable {
    var id: String
    var name: String
    var type: ClientType
    var contactInfo: ContactInfo
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        type: ClientType = .personal,
        contactInfo: ContactInfo = ContactInfo(),
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.contactInfo = contactInfo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum ClientType: String, Codable, Sendable, CaseIterable {
        case personal
        case corporate
    }

    struct ContactInfo: Codable, Sendable {
        var email: String = ""
        var phone: String = ""
        var address: String = ""
    }
}

extension Client: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        type = ClientType(rawValue: row["type"] as String) ?? .personal
        let jsonStr: String = row["contact_info"] ?? "{}"
        contactInfo = (try? JSONDecoder().decode(ContactInfo.self, from: Data(jsonStr.utf8))) ?? ContactInfo()
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }
}

extension Client: PersistableRecord {
    static let databaseTableName = "clients"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["name"] = name
        container["type"] = type.rawValue
        container["contact_info"] = String(data: try JSONEncoder().encode(contactInfo), encoding: .utf8) ?? "{}"
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }
}
