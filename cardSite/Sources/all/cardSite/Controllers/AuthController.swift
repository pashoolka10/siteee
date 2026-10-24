import Vapor
import Fluent

struct RegisterForm: Content, Validatable {
    let login: String
    let password: String
    let fullName: String
    let email: String
    let avatarURL: String?

    static func validations(_ validations: inout Validations) {
        validations.add("login", as: String.self, is: .count(3...30) && .alphanumeric)
        validations.add("password", as: String.self, is: .count(6...))
        validations.add("fullName", as: String.self, is: .count(3...))
        validations.add("email", as: String.self, is: .email)
    }
}

struct EditProfileForm: Content, Validatable {
    let fullName: String
    let email: String
    let newPassword: String?

    static func validations(_ validations: inout Validations) {
        validations.add("fullName", as: String.self, is: .count(3...))
        validations.add("email", as: String.self, is: .email)
        validations.add("newPassword", as: String?.self, is: .nil || .count(6...))
    }
}

struct LoginForm: Content {
    let login: String
    let password: String
}

struct ProfileContext: Content {
    let user: User
    let avatarLetter: String
    let error: String
    let orders: [Order]
}

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("register", use: registerPage)
        routes.post("register", use: register)
        routes.get("login",    use: loginPage)
        routes.post("login",    use: login)
        routes.get("logout",   use: logout)

        routes.get("forgot",  use: forgotPage)
        routes.post("forgot", use: forgot)
        routes.get("reset",   use: resetPage)
        routes.post("reset",  use: resetSave)

        let protected = routes.grouped(RequireAuthMiddleware())
        protected.get("profile",          use: profilePage)
        protected.get("profile", "edit",  use: editPage)
        protected.post("profile", "edit", use: editSave)
    }

    func registerPage(req: Request) async throws -> View {
        return try await req.view.render("register")
    }

    func register(req: Request) async throws -> Response {
        do {
            try RegisterForm.validate(content: req)
        } catch {
            return req.redirect(to: "/?error=\(error.localizedDescription)&tab=register")
        }

        let form = try req.content.decode(RegisterForm.self)

        if try await User.query(on: req.db).filter(\.$login == form.login).first() != nil {
            return req.redirect(to: "/?error=Логин+занят&tab=register")
        }
        if try await User.query(on: req.db).filter(\.$email == form.email).first() != nil {
            return req.redirect(to: "/?error=Email+занят&tab=register")
        }

        let user = User(
            login: form.login,
            passwordHash: try Bcrypt.hash(form.password),
            fullName: form.fullName,
            email: form.email,
            avatarURL: (form.avatarURL?.isEmpty == false) ? form.avatarURL : nil
        )
        try await user.save(on: req.db)

        req.session.data["user_id"] = user.id?.uuidString
        req.session.data["user_login"] = user.login
        req.session.data["user_name"] = user.fullName
        req.session.data["user_email"] = user.email
        req.session.data["user_letter"] = String(user.fullName.prefix(1))

        // ЛОГИРОВАНИЕ: Регистрация
        logAction("Регистрация аккаунта", page: "/register", req: req)

        return req.redirect(to: "/profile")
    }

    func loginPage(req: Request) async throws -> View {
        return try await req.view.render("login")
    }

    func login(req: Request) async throws -> Response {
        let form = try req.content.decode(LoginForm.self)

        guard let user = try await User.query(on: req.db).filter(\.$login == form.login).first() else {
            return req.redirect(to: "/?error=Неверный+логин+или+пароль")
        }
        guard try Bcrypt.verify(form.password, created: user.passwordHash) else {
            return req.redirect(to: "/?error=Неверный+логин+или+пароль")
        }

        req.session.data["user_id"] = user.id?.uuidString
        req.session.data["user_login"] = user.login
        req.session.data["user_name"] = user.fullName
        req.session.data["user_email"] = user.email
        req.session.data["user_letter"] = String(user.fullName.prefix(1))
        req.session.data["user_avatar"] = user.avatarURL ?? ""

        // ЛОГИРОВАНИЕ: Вход
        logAction("Авторизация", page: "/login", req: req)

        return req.redirect(to: "/profile")
    }

    func logout(req: Request) async throws -> Response {
        // ЛОГИРОВАНИЕ: Выход
        logAction("Выход из системы", page: "/logout", req: req)
        
        req.session.destroy()
        return req.redirect(to: "/")
    }

    func profilePage(req: Request) async throws -> View {
        guard let idString = req.session.data["user_id"],
              let id = UUID(uuidString: idString),
              let user = try await User.find(id, on: req.db)
        else { throw Abort(.unauthorized) }

        let orders = try await Order.query(on: req.db)
            .filter(\.$user.$id == id)
            .sort(\.$createdAt, .descending)
            .all()

        let context = ProfileContext(
            user: user,
            avatarLetter: String(user.fullName.prefix(1)),
            error: req.query[String.self, at: "error"] ?? "",
            orders: orders
        )
        
        // ЛОГИРОВАНИЕ: Посещение профиля
        logAction("Посещение профиля", page: "/profile", req: req)
        
        return try await req.view.render("profile", context)
    }

    func editPage(req: Request) async throws -> View {
        guard let idString = req.session.data["user_id"],
              let id = UUID(uuidString: idString),
              let user = try await User.find(id, on: req.db)
        else { throw Abort(.unauthorized) }

        let context = ProfileContext(
            user: user,
            avatarLetter: String(user.fullName.prefix(1)),
            error: req.query[String.self, at: "error"] ?? "",
            orders: []
        )
        return try await req.view.render("edit", context)
    }

    func editSave(req: Request) async throws -> Response {
        guard let idString = req.session.data["user_id"],
              let id = UUID(uuidString: idString),
              let user = try await User.find(id, on: req.db)
        else { return req.redirect(to: "/?need_auth=1") }

        do {
            try EditProfileForm.validate(content: req)
        } catch {
            return req.redirect(to: "/profile/edit?error=\(error.localizedDescription)")
        }

        let form = try req.content.decode(EditProfileForm.self)

        if let other = try await User.query(on: req.db).filter(\.$email == form.email).first(),
           other.id != user.id {
            return req.redirect(to: "/profile/edit?error=Эта+почта+уже+занята")
        }

        user.fullName = form.fullName
        user.email = form.email

        if let newPassword = form.newPassword, !newPassword.isEmpty {
            user.passwordHash = try Bcrypt.hash(newPassword)
        }

        try await user.save(on: req.db)

        req.session.data["user_name"] = user.fullName
        req.session.data["user_email"] = user.email
        req.session.data["user_letter"] = String(user.fullName.prefix(1))

        // ЛОГИРОВАНИЕ: Редактирование
        logAction("Редактирование профиля", page: "/profile/edit", req: req)

        return req.redirect(to: "/profile")
    }

    func forgotPage(req: Request) async throws -> View {
        return try await req.view.render("forgot", ["link": "", "message": ""])
    }

    func forgot(req: Request) async throws -> View {
        let email = try req.content.get(String.self, at: "email")

        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            return try await req.view.render("forgot", ["link": "", "message": "Пользователь с такой почтой не найден"])
        }

        let token = UUID().uuidString
        user.resetToken = token
        user.resetExpires = Date().addingTimeInterval(15 * 60)
        try await user.save(on: req.db)

        return try await req.view.render("forgot", ["link": "/reset?token=\(token)", "message": ""])
    }

    func resetPage(req: Request) async throws -> View {
        let token = req.query[String.self, at: "token"] ?? ""
        let error = req.query[String.self, at: "error"] ?? ""

        if error.isEmpty {
            guard let user = try await User.query(on: req.db).filter(\.$resetToken == token).first(),
                  let expires = user.resetExpires, expires > Date()
            else {
                return try await req.view.render("reset", ["token": "", "error": "Ссылка недействительна или устарела"])
            }
        }

        return try await req.view.render("reset", ["token": token, "error": error])
    }

    func resetSave(req: Request) async throws -> Response {
        let token    = try req.content.get(String.self, at: "token")
        let password = try req.content.get(String.self, at: "password")

        guard password.count >= 6 else {
            return req.redirect(to: "/reset?token=\(token)&error=Пароль+не+короче+6+символов")
        }

        guard let user = try await User.query(on: req.db).filter(\.$resetToken == token).first(),
              let expires = user.resetExpires, expires > Date()
        else {
            return req.redirect(to: "/reset?token=\(token)&error=Ссылка+недействительна")
        }

        user.passwordHash = try Bcrypt.hash(password)
        user.resetToken = nil
        user.resetExpires = nil
        try await user.save(on: req.db)

        return req.redirect(to: "/?message=Пароль+изменён,+войдите")
    }
}
