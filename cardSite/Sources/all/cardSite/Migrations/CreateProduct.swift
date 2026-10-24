import Fluent

struct CreateProduct: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("products")
            .id() // <-- ВАЖНО: теперь ID автоматический (UUID)
            .field("name", .string, .required)
            .field("platform", .string, .required)
            .field("country", .string, .required)
            .field("nominal", .string, .required)
            .field("price", .int, .required)
            .field("old_price", .int)
            .field("rating", .double, .required)
            .field("popular", .int, .required)
            .field("image", .string, .required)
            .field("description", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("products").delete()
    }
}
