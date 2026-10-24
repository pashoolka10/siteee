import Vapor
import Fluent
import NIOFoundationEssentialsCompat
struct ProductForm: Content, Validatable {
    let name: String
    let platform: String
    let country: String
    let nominal: String
    let price: Int
    let oldPrice: String? // <-- ИЗМЕНЕНО: теперь это строка, чтобы пустое поле не ломалось
    let rating: Double
    let popular: Int
    let description: String

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(3...) && !.empty)
        validations.add("price", as: Int.self, is: .range(1...))
        validations.add("rating", as: Double.self, is: .range(0...5))
    }
}

struct AdminProductItem: Content {
    let id: String
    let name: String
    let platformTitle: String
    let price: Int
}

struct AdminListContext: Content {
    let products: [AdminProductItem]
    let userLogin: String
    let avatarLetter: String
    let userAvatar: String
}

struct AdminFormContext: Content {
    let product: Product?
    let error: String
    let userLogin: String
    let avatarLetter: String
    let userAvatar: String
}

struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped(RequireAuthMiddleware()).grouped("admin")
        admin.get(use: list)
        admin.get("new", use: newForm)
        admin.post("new", use: create)
        admin.get("edit", ":id", use: editForm)
        admin.post("edit", ":id", use: update)
        admin.post("delete", ":id", use: delete)
    }

    func list(req: Request) async throws -> View {
        let dbProducts = try await Product.query(on: req.db).sort(\.$name).all()
        
        let items = dbProducts.map { product in
            AdminProductItem(
                id: product.id?.uuidString ?? "",
                name: product.name,
                platformTitle: platformTitles[product.platform] ?? product.platform,
                price: product.price
            )
        }

        return try await req.view.render("admin_list", AdminListContext(
            products: items,
            userLogin: req.session.data["user_login"] ?? "",
            avatarLetter: req.session.data["user_letter"] ?? "Г",
            userAvatar: req.session.data["user_avatar"] ?? ""
        ))
    }

    func newForm(req: Request) async throws -> View {
        let error = req.query[String.self, at: "error"] ?? ""
        return try await req.view.render("admin_form", AdminFormContext(
            product: nil, error: error,
            userLogin: req.session.data["user_login"] ?? "",
            avatarLetter: req.session.data["user_letter"] ?? "Г",
            userAvatar: req.session.data["user_avatar"] ?? ""
        ))
    }

    func create(req: Request) async throws -> Response {
        do { try ProductForm.validate(content: req) } catch {
            return req.redirect(to: "/admin/new?error=\(error.localizedDescription)")
        }

        let form = try req.content.decode(ProductForm.self)
        
        // Превращаем строку обратно в число (если пусто, будет nil)
        let parsedOldPrice = Int(form.oldPrice ?? "")
        
        var imagePath = "/images/default.jpg"
        if let file = try? req.content.get(File.self, at: "imageFile"), file.data.readableBytes > 0 {
            let fileName = "\(UUID().uuidString).\(file.extension ?? "jpg")"
            let folder = req.application.directory.publicDirectory + "images/"
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
            try Data(buffer: file.data).write(to: URL(fileURLWithPath: folder + fileName))
            imagePath = "/images/\(fileName)"
        }

        let product = Product(
            name: form.name, platform: form.platform, country: form.country,
            nominal: form.nominal, price: form.price, oldPrice: parsedOldPrice, // <-- Используем parsedOldPrice
            rating: form.rating, popular: form.popular, image: imagePath, description: form.description
        )
        try await product.save(on: req.db)
        return req.redirect(to: "/admin")
    }

    func editForm(req: Request) async throws -> View {
        guard let id = req.parameters.get("id"), let uuid = UUID(uuidString: id),
              let product = try await Product.find(uuid, on: req.db) else { throw Abort(.notFound) }
        
        let error = req.query[String.self, at: "error"] ?? ""
        return try await req.view.render("admin_form", AdminFormContext(
            product: product, error: error,
            userLogin: req.session.data["user_login"] ?? "",
            avatarLetter: req.session.data["user_letter"] ?? "Г",
            userAvatar: req.session.data["user_avatar"] ?? ""
        ))
    }

    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id"), let uuid = UUID(uuidString: id),
              let product = try await Product.find(uuid, on: req.db) else { throw Abort(.notFound) }
              
        do { try ProductForm.validate(content: req) } catch {
            return req.redirect(to: "/admin/edit/\(id)?error=\(error.localizedDescription)")
        }

        let form = try req.content.decode(ProductForm.self)
        let parsedOldPrice = Int(form.oldPrice ?? "") // <-- Конвертация
        
        product.name = form.name
        product.platform = form.platform
        product.country = form.country
        product.nominal = form.nominal
        product.price = form.price
        product.oldPrice = parsedOldPrice // <-- Используем parsedOldPrice
        product.rating = form.rating
        product.popular = form.popular
        product.description = form.description
        
        if let file = try? req.content.get(File.self, at: "imageFile"), file.data.readableBytes > 0 {
            let fileName = "\(UUID().uuidString).\(file.extension ?? "jpg")"
            let folder = req.application.directory.publicDirectory + "images/"
            try Data(buffer: file.data).write(to: URL(fileURLWithPath: folder + fileName))
            product.image = "/images/\(fileName)"
        }
        
        try await product.save(on: req.db)
        return req.redirect(to: "/admin")
    }

    func delete(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id"), let uuid = UUID(uuidString: id),
              let product = try await Product.find(uuid, on: req.db) else { throw Abort(.notFound) }
        try await product.delete(on: req.db)
        return req.redirect(to: "/admin")
    }
}
