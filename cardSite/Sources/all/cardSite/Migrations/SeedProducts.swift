import Fluent

struct SeedProducts: AsyncMigration {
    func prepare(on database: Database) async throws {
        let products = [
            Product(name: "PlayStation Store Индия 1000 INR", platform: "playstation", country: "india", nominal: "1000 INR", price: 1190, oldPrice: 1490, rating: 4.9, popular: 100, image: "/images/ps-india-1000.jpg", description: "Карта пополнения кошелька PSN."),
            Product(name: "PlayStation Store Индия 2000 INR", platform: "playstation", country: "india", nominal: "2000 INR", price: 2290, oldPrice: 2690, rating: 4.9, popular: 92, image: "/images/ps-india-2000.jpg", description: "Увеличенный номинал для индийского аккаунта."),
            Product(name: "PlayStation Store Турция 500 TRY", platform: "playstation", country: "turkey", nominal: "500 TRY", price: 1490, oldPrice: nil, rating: 4.8, popular: 88, image: "/images/ps-turkey-500.svg", description: "Турецкий регион PSN."),
            Product(name: "PlayStation Store Турция 1000 TRY", platform: "playstation", country: "turkey", nominal: "1000 TRY", price: 2790, oldPrice: nil, rating: 4.8, popular: 84, image: "/images/ps-turkey-1000.svg", description: "Пополнение турецкого кошелька PSN."),
            Product(name: "Apple Gift Card США 25 USD", platform: "apple", country: "usa", nominal: "25 USD", price: 2690, oldPrice: nil, rating: 4.9, popular: 95, image: "/images/apple-usa-25.jpg", description: "Карта для американского Apple ID."),
            Product(name: "Apple Gift Card США 100 USD", platform: "apple", country: "usa", nominal: "100 USD", price: 9890, oldPrice: 10490, rating: 4.9, popular: 90, image: "/images/apple-usa-100.jpg", description: "Большой номинал для американского аккаунта."),
            Product(name: "Apple Gift Card Канада 15 CAD", platform: "apple", country: "canada", nominal: "15 CAD", price: 1190, oldPrice: nil, rating: 4.7, popular: 70, image: "/images/apple-canada-15.jpg", description: "Небольшая карта для канадского Apple ID."),
            Product(name: "Apple Gift Card Канада 100 CAD", platform: "apple", country: "canada", nominal: "100 CAD", price: 7190, oldPrice: nil, rating: 4.7, popular: 66, image: "/images/apple-canada-100.jpg", description: "Максимальный номинал для канадского региона."),
            Product(name: "GTA VI (PS5). Стандартное издание", platform: "games", country: "russia", nominal: "Стандартное издание", price: 8990, oldPrice: 9490, rating: 5.0, popular: 98, image: "/images/gta6.jpg", description: "Ключ активации GTA VI для PS5."),
            Product(name: "GTA VI (PS5). Deluxe Edition", platform: "games", country: "russia", nominal: "Deluxe издание", price: 11490, oldPrice: nil, rating: 5.0, popular: 74, image: "/images/gta6.jpg", description: "Расширенное издание GTA VI.")
        ]
        
        for product in products {
            try await product.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await Product.query(on: database).delete()
    }
}
