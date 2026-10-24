import Vapor
import Fluent

struct CartItem: Content {
    let id: String
    let name: String
    let image: String
    let count: Int
    let sum: Int
    let price: Int
}

struct CartContext: Content {
    let userLogin: String
    let avatarLetter: String
    let userName: String
    let userEmail: String
    let userAvatar: String
    let items: [CartItem]
    let total: Int
    let isEmpty: Bool
}

struct CartController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let cart = routes.grouped(RequireAuthMiddleware()).grouped("cart")
        cart.get(use: show)
        cart.post("add",    use: add)
        cart.post("remove", use: remove)
        cart.post("change", use: change)
        cart.post("order",  use: order)
    }

    func show(req: Request) async throws -> View {
        let cart = loadCart(req.session)

        var items: [CartItem] = []
        var total = 0

        for (idString, count) in cart {
            guard let id = UUID(uuidString: idString) else { continue }
            guard let product = try await Product.find(id, on: req.db) else { continue }
            let sum = product.price * count
            total += sum
            
            items.append(CartItem(
                id: idString,
                name: product.name,
                image: product.image,
                count: count,
                sum: sum,
                price: product.price
            ))
        }

        let context = CartContext(
            userLogin: req.session.data["user_login"] ?? "",
            avatarLetter: req.session.data["user_letter"] ?? "Г",
            userName: req.session.data["user_name"] ?? "",
            userEmail: req.session.data["user_email"] ?? "",
            userAvatar: req.session.data["user_avatar"] ?? "",
            items: items,
            total: total,
            isEmpty: items.isEmpty
        )
        return try await req.view.render("cart", context)
    }

    func add(req: Request) async throws -> Response {
        let productID = try req.content.get(String.self, at: "productId")
        
        guard let uuid = UUID(uuidString: productID),
              let product = try await Product.find(uuid, on: req.db) else {
            return req.redirect(to: "/catalog")
        }

        var cart = loadCart(req.session)
        cart[productID] = (cart[productID] ?? 0) + 1
        saveCart(cart, req.session)

        await logAction("В корзину: \(product.name)", page: "/cart", req: req)

        return req.redirect(to: "/cart")
    }

    func remove(req: Request) async throws -> Response {
        let productID = try req.content.get(String.self, at: "productId")
        var cart = loadCart(req.session)
        cart.removeValue(forKey: productID)
        saveCart(cart, req.session)

        await logAction("Удаление из корзины", page: "/cart/remove", req: req)

        return req.redirect(to: "/cart")
    }

    func change(req: Request) async throws -> Response {
        let productID = try req.content.get(String.self, at: "productId")
        let delta     = try req.content.get(Int.self,    at: "delta")
        
        var cart = loadCart(req.session)
        let count = (cart[productID] ?? 0) + delta
        if count <= 0 {
            cart.removeValue(forKey: productID)
        } else {
            cart[productID] = count
        }
        saveCart(cart, req.session)
        
        return req.redirect(to: "/cart")
    }

    func order(req: Request) async throws -> Response {
        guard let idString = req.session.data["user_id"],
              let userID = UUID(uuidString: idString) else {
            return req.redirect(to: "/?need_auth=1")
        }

        let customerName  = try req.content.get(String.self, at: "customerName")
        let customerEmail = try req.content.get(String.self, at: "customerEmail")

        let cart = loadCart(req.session)
        guard !cart.isEmpty else { return req.redirect(to: "/cart") }

        var lines: [String] = []
        var itemNames: [String] = []
        var total = 0
        
        for (idString, count) in cart {
            guard let id = UUID(uuidString: idString) else { continue }
            guard let product = try await Product.find(id, on: req.db) else { continue }
            let sum = product.price * count
            total += sum
            lines.append("\(product.name) — \(count) шт. = \(sum) ₽")
            itemNames.append(product.name)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        let order = Order(
            userID: userID,
            items: lines.joined(separator: "; "),
            total: total,
            customerName: customerName,
            customerEmail: customerEmail,
            dateText: formatter.string(from: Date())
        )
        try await order.save(on: req.db)

        let itemsString = itemNames.joined(separator: ", ")
        await logAction("Покупка: \(itemsString)", page: "/cart/order", req: req)

        req.session.data["cart"] = ""
        return req.redirect(to: "/profile")
    }

    private func loadCart(_ session: Session) -> [String: Int] {
        var result: [String: Int] = [:]
        let text = session.data["cart"] ?? ""
        for part in text.split(separator: ",") {
            let kv = part.split(separator: ":")
            if kv.count == 2, let count = Int(kv[1]) {
                result[String(kv[0])] = count
            }
        }
        return result
    }

    private func saveCart(_ cart: [String: Int], _ session: Session) {
        var parts: [String] = []
        for (id, count) in cart {
            parts.append("\(id):\(count)")
        }
        session.data["cart"] = parts.joined(separator: ",")
    }
}
