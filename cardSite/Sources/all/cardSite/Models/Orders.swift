import Fluent
import Vapor

// Покупка (заказ) пользователя — одна строка в таблице orders
final class Order: Model, Content, @unchecked Sendable {
    static let schema = "orders"

    @ID(key: .id) var id: UUID?

    // чья покупка (связь с таблицей users)
    @Parent(key: "user_id") var user: User

    @Field(key: "items") var items: String                 
    @Field(key: "total") var total: Int
    @Field(key: "customer_name") var customerName: String
    @Field(key: "customer_email") var customerEmail: String
    @Field(key: "date_text") var dateText: String
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() { }

    init(userID: UUID, items: String, total: Int,
         customerName: String, customerEmail: String, dateText: String) {
        self.$user.id = userID
        self.items = items
        self.total = total
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.dateText = dateText
    }
}
