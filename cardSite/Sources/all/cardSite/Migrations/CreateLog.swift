import Fluent

struct CreateLog: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("logs")
            .id()
            .field("action", .string, .required)
            .field("page", .string, .required)
            .field("user_id", .uuid)
            .field("created_at", .datetime)
            .create()
    }
    func revert(on database: Database) async throws {
        try await database.schema("logs").delete()
    }
}
