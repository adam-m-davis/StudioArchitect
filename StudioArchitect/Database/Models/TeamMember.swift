import Foundation
import GRDB

struct TeamMember: Identifiable, Sendable {
    var id: String
    var name: String
    var role: String
    var contactInfo: ContactInfo
    var paymentInfo: PaymentInfo
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        role: String,
        contactInfo: ContactInfo = ContactInfo(),
        paymentInfo: PaymentInfo = PaymentInfo(),
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.contactInfo = contactInfo
        self.paymentInfo = paymentInfo
        self.createdAt = createdAt
    }

    struct ContactInfo: Codable, Sendable {
        var email: String = ""
        var phone: String = ""
    }

    struct PaymentInfo: Codable, Sendable {
        var defaultRate: Double?
        var paymentMethod: String?
        var notes: String?
    }
}

extension TeamMember: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        role = row["role"]
        let contactStr: String = row["contact_info"] ?? "{}"
        contactInfo = (try? JSONDecoder().decode(ContactInfo.self, from: Data(contactStr.utf8))) ?? ContactInfo()
        let paymentStr: String = row["payment_info"] ?? "{}"
        paymentInfo = (try? JSONDecoder().decode(PaymentInfo.self, from: Data(paymentStr.utf8))) ?? PaymentInfo()
        createdAt = row["created_at"]
    }
}

extension TeamMember: PersistableRecord {
    static let databaseTableName = "team_members"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["name"] = name
        container["role"] = role
        container["contact_info"] = String(data: try JSONEncoder().encode(contactInfo), encoding: .utf8) ?? "{}"
        container["payment_info"] = String(data: try JSONEncoder().encode(paymentInfo), encoding: .utf8) ?? "{}"
        container["created_at"] = createdAt
    }
}
