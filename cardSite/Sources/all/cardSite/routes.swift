import Vapor
import Fluent

func routes(_ app: Application) throws {
    app.get { req async throws -> View in
        return try await req.view.render("index", [
            "userLogin": req.session.data["user_login"] ?? "",
            "avatarLetter": req.session.data["user_letter"] ?? "Г",
            "userAvatar": req.session.data["user_avatar"] ?? ""
        ])
    }

    app.get("about") { req async throws -> View in
        return try await req.view.render("about", [
            "userLogin": req.session.data["user_login"] ?? "",
            "avatarLetter": req.session.data["user_letter"] ?? "Г",
            "userAvatar": req.session.data["user_avatar"] ?? ""
        ])
    }

    try app.register(collection: AuthController())
    try app.register(collection: CatalogController())
    try app.register(collection: CartController())
    try app.register(collection: AdminController())
    try app.register(collection: StatsController())
}
