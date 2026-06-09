import Foundation
import GRDB

struct Backup: Identifiable, Sendable {
    var id: String
    var sessionId: String
    var locationType: LocationType
    var path: String
    var fileCount: Int
    var checksumVerified: Bool
    var verifiedAt: Date?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        locationType: LocationType,
        path: String,
        fileCount: Int = 0,
        checksumVerified: Bool = false,
        verifiedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionId = sessionId
        self.locationType = locationType
        self.path = path
        self.fileCount = fileCount
        self.checksumVerified = checksumVerified
        self.verifiedAt = verifiedAt
        self.createdAt = createdAt
    }

    enum LocationType: String, Codable, Sendable, CaseIterable {
        case workArea = "work_area"
        case localBackup = "local_backup"
        case offsite

        var displayName: String {
            switch self {
            case .workArea: return "Work Area"
            case .localBackup: return "Local Backup"
            case .offsite: return "Offsite"
            }
        }

        var icon: String {
            switch self {
            case .workArea: return "internaldrive"
            case .localBackup: return "externaldrive"
            case .offsite: return "cloud"
            }
        }
    }
}

extension Backup: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        sessionId = row["session_id"]
        locationType = LocationType(rawValue: row["location_type"] as String) ?? .workArea
        path = row["path"]
        fileCount = row["file_count"]
        checksumVerified = row["checksum_verified"]
        verifiedAt = row["verified_at"]
        createdAt = row["created_at"]
    }
}

extension Backup: PersistableRecord {
    static let databaseTableName = "backups"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["session_id"] = sessionId
        container["location_type"] = locationType.rawValue
        container["path"] = path
        container["file_count"] = fileCount
        container["checksum_verified"] = checksumVerified
        container["verified_at"] = verifiedAt
        container["created_at"] = createdAt
    }
}
