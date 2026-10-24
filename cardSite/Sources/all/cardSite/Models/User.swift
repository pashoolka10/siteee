import Fluent
import Vapor
import Foundation

// Модель пользователя — это как "представление" строки в таблице users
final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id) var id: UUID?

    @Field(key: "login")
    var login: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "full_name")
    var fullName: String

    @Field(key: "email")
    var email: String

    @OptionalField(key: "avatar_url")
    var avatarURL: String?

    // поля для восстановления пароля (п.6)
    @OptionalField(key: "reset_token")
    var resetToken: String?

    @OptionalField(key: "reset_expires")
    var resetExpires: Date?

    init() { }

    init(login: String, passwordHash: String, fullName: String, email: String, avatarURL: String?) {
        self.login = login
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.email = email
        self.avatarURL = avatarURL
    }
}
