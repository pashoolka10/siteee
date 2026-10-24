import Vapor
import Fluent

// Галочка фильтра: значение, подпись, отмечена ли и доступна ли
struct FilterOption: Content {
    let value: String
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
}

// Данные для catalog.leaf
struct CatalogContext: Content {
    let products: [Product]
    let isEmpty: Bool
    let userLogin: String
    let avatarLetter: String
    let userAvatar: String
    let platformOptions: [FilterOption]
    let countryOptions: [FilterOption]
    let maxPrice: Int
    let maxPriceLimit: Int
    let sort: String
}

struct CatalogController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("catalog", use: show)
    }

    func show(req: Request) async throws -> View {

        let allProducts = try await Product.query(on: req.db).all()

                // 2. Параметры фильтра из адресной строки
                let platforms = req.query[[String].self, at: "platform"] ?? []
                let countries = req.query[[String].self, at: "country"] ?? []
                let maxPrice  = req.query[Int.self, at: "maxPrice"] ?? maxPriceLimit
                let sort      = req.query[String.self, at: "sort"] ?? "popular"

                // 3. Фильтруем товары
                var products = allProducts.filter { product in
                    (platforms.isEmpty || platforms.contains(product.platform)) &&
                    (countries.isEmpty || countries.contains(product.country)) &&
                    product.price <= maxPrice
                }

        // Сортируем
        switch sort {
        case "price-asc":  products.sort { $0.price < $1.price }
        case "price-desc": products.sort { $0.price > $1.price }
        case "rating":     products.sort { $0.rating > $1.rating }
        default:           products.sort { $0.popular > $1.popular }
        }

        // Умный фильтр: галочка серая, если с ней ничего не найдётся
        let platformOptions = allPlatforms.map { platform -> FilterOption in
            let isSelected = platforms.contains(platform)
            let hasProducts = allProducts.contains { product in
                product.platform == platform &&
                (countries.isEmpty || countries.contains(product.country)) &&
                product.price <= maxPrice
            }
            return FilterOption(
                value: platform,
                title: platformTitles[platform] ?? platform,
                isSelected: isSelected,
                isDisabled: platform != "steam" && !isSelected && !hasProducts
            )
        }

        let countryOptions = allCountries.map { country -> FilterOption in
            let isSelected = countries.contains(country)
            let hasProducts = allProducts.contains { product in
                product.country == country &&
                (platforms.isEmpty || platforms.contains(product.platform)) &&
                product.price <= maxPrice
            }
            return FilterOption(
                value: country,
                title: countryTitles[country] ?? country,
                isSelected: isSelected,
                isDisabled: !isSelected && !hasProducts
            )
        }

        // Логин и буква для шапки — из сессии, без запроса в базу
        let context = CatalogContext(
            products: products,
            isEmpty: products.isEmpty,
            userLogin: req.session.data["user_login"] ?? "",
            avatarLetter: req.session.data["user_letter"] ?? "Г",
            userAvatar: req.session.data["user_avatar"] ?? "",
            platformOptions: platformOptions,
            countryOptions: countryOptions,
            maxPrice: maxPrice,
            maxPriceLimit: maxPriceLimit,
            sort: sort
        )

        return try await req.view.render("catalog", context)
    }
}
