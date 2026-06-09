import Foundation
import GRDB
import SwiftUI

// MARK: - AppDatabase

final class AppDatabase: Sendable {

    static let shared = AppDatabase.makeShared()

    let dbQueue: DatabaseQueue

    private init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    private static func makeShared() -> AppDatabase {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbDirectoryURL = appSupportURL.appendingPathComponent("StudioArchitect", isDirectory: true)
            try fileManager.createDirectory(at: dbDirectoryURL, withIntermediateDirectories: true)
            let dbURL = dbDirectoryURL.appendingPathComponent("studio.db")

            var config = Configuration()
            config.foreignKeysEnabled = true

            let dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
            let db = AppDatabase(dbQueue: dbQueue)
            try db.applyMigrations()
            return db
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    private func applyMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "clients") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("type", .text).notNull()
                t.column("contact_info", .text).notNull().defaults(to: "{}")
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "sessions") { t in
                t.primaryKey("id", .text).notNull()
                t.column("client_id", .text).notNull().references("clients", onDelete: .restrict)
                t.column("name", .text).notNull()
                t.column("type", .text).notNull()
                t.column("shoot_date", .date).notNull()
                t.column("location", .text)
                t.column("current_stage", .text).notNull().defaults(to: "imported")
                t.column("source_path", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "photo_files") { t in
                t.primaryKey("id", .text).notNull()
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("filename", .text).notNull()
                t.column("path", .text).notNull()
                t.column("file_type", .text).notNull()
                t.column("status", .text).notNull().defaults(to: "imported")
                t.column("exif_data", .text)
                t.column("checksum", .text)
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            try db.create(table: "team_members") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("role", .text).notNull()
                t.column("contact_info", .text).notNull().defaults(to: "{}")
                t.column("payment_info", .text).defaults(to: "{}")
                t.column("created_at", .datetime).notNull()
            }

            try db.create(table: "session_team") { t in
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("team_id", .text).notNull().references("team_members", onDelete: .restrict)
                t.column("role", .text)
                t.column("payment_amount", .double)
                t.column("payment_status", .text).notNull().defaults(to: "pending")
                t.primaryKey(["session_id", "team_id"])
            }

            try db.create(table: "backups") { t in
                t.primaryKey("id", .text).notNull()
                t.column("session_id", .text).notNull().references("sessions", onDelete: .cascade)
                t.column("location_type", .text).notNull()
                t.column("path", .text).notNull()
                t.column("file_count", .integer).notNull().defaults(to: 0)
                t.column("checksum_verified", .boolean).notNull().defaults(to: false)
                t.column("verified_at", .datetime)
                t.column("created_at", .datetime).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    @Entry var appDatabase: AppDatabase = .shared
}
