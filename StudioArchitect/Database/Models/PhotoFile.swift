import Foundation
import GRDB

struct PhotoFile: Identifiable, Sendable {
    var id: String
    var sessionId: String
    var filename: String
    var path: String
    var fileType: String
    var status: FileStatus
    var exifData: ExifData?
    var checksum: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        sessionId: String,
        filename: String,
        path: String,
        fileType: String,
        status: FileStatus = .imported,
        exifData: ExifData? = nil,
        checksum: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.sessionId = sessionId
        self.filename = filename
        self.path = path
        self.fileType = fileType
        self.status = status
        self.exifData = exifData
        self.checksum = checksum
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum FileStatus: String, Codable, Sendable, CaseIterable {
        case imported
        case keeper
        case reject
        case maybe
        case firstPassComplete = "first_pass_complete"
        case edited
        case exported
        case delivered
        case archived
    }

    struct ExifData: Codable, Sendable {
        var camera: String?
        var lens: String?
        var focalLength: String?
        var aperture: String?
        var shutterSpeed: String?
        var iso: Int?
        var dateTaken: Date?
    }
}

extension PhotoFile: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        sessionId = row["session_id"]
        filename = row["filename"]
        path = row["path"]
        fileType = row["file_type"]
        status = FileStatus(rawValue: row["status"] as String) ?? .imported
        if let jsonStr: String = row["exif_data"] {
            exifData = try? JSONDecoder().decode(ExifData.self, from: Data(jsonStr.utf8))
        }
        checksum = row["checksum"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }
}

extension PhotoFile: PersistableRecord {
    static let databaseTableName = "photo_files"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["session_id"] = sessionId
        container["filename"] = filename
        container["path"] = path
        container["file_type"] = fileType
        container["status"] = status.rawValue
        if let exifData {
            container["exif_data"] = String(data: try JSONEncoder().encode(exifData), encoding: .utf8)
        }
        container["checksum"] = checksum
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }
}
