import Fluent

// Миграция создаёт таблицу users в базе при первом запуске
struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("login", .string, .required)
            .field("password_hash", .string, .required)
            .field("full_name", .string, .required)
            .field("email", .string, .required)
            .field("avatar_url", .string)
            .field("reset_token", .string)
            .field("reset_expires", .datetime)    
            .unique(on: "login")
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}
