import Fluent
import Vapor

final class Product: Model, Content, @unchecked Sendable {
    static let schema = "products"

    // АВТОМАТИЧЕСКИЙ ID (UUID)!
    @ID(key: .id) var id: UUID?

    @Field(key: "name")        var name: String
    @Field(key: "platform")    var platform: String
    @Field(key: "country")     var country: String
    @Field(key: "nominal")     var nominal: String
    @Field(key: "price")       var price: Int
    @OptionalField(key: "old_price") var oldPrice: Int?
    @Field(key: "rating")      var rating: Double
    @Field(key: "popular")     var popular: Int
    @Field(key: "image")       var image: String
    @Field(key: "description") var description: String

    init() { }
    
    init(id: UUID? = nil, name: String, platform: String, country: String, nominal: String, price: Int, oldPrice: Int?, rating: Double, popular: Int, image: String, description: String) {
        self.id = id
        self.name = name
        self.platform = platform
        self.country = country
        self.nominal = nominal
        self.price = price
        self.oldPrice = oldPrice
        self.rating = rating
        self.popular = popular
        self.image = image
        self.description = description
    }
}

let platformTitles = ["playstation": "PlayStation", "apple": "Apple", "steam": "Steam", "games": "Игры"]
let countryTitles = ["india": "Индия", "turkey": "Турция", "usa": "США", "canada": "Канада", "russia": "Россия"]
let allPlatforms = ["playstation", "apple", "steam", "games"]
let allCountries = ["india", "turkey", "usa", "canada", "russia"]
let maxPriceLimit = 12000
