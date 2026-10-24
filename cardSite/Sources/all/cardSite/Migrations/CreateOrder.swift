import Fluent

// Создаёт таблицу orders — здесь хранятся покупки пользователей
struct CreateOrder: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("orders")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("items", .string, .required)
            .field("total", .int, .required)
            .field("customer_name", .string, .required)
            .field("customer_email", .string, .required)
            .field("date_text", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("orders").delete()
    }
}
