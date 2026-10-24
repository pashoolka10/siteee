import Fluent
import Vapor

final class Log: Model, Content, @unchecked Sendable {
    static let schema = "logs"
    @ID(key: .id) var id: UUID?
    @Field(key: "action") var action: String
    @Field(key: "page") var page: String
    @OptionalField(key: "user_id") var userID: UUID?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
    init(action: String, page: String, userID: UUID? = nil) {
        self.action = action
        self.page = page
        self.userID = userID
    }
}
