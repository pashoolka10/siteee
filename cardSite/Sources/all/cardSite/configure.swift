import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

func configure(_ app: Application) async throws {

    var tls = TLSConfiguration.makeClientConfiguration()
    tls.certificateVerification = .none
    let sslContext = try NIOSSLContext(configuration: tls)

    let config = SQLPostgresConfiguration(
        hostname: "aws-0-eu-west-1.pooler.supabase.com",
        port: 5432,
        username: "postgres.afyorsuducexmqlngwxc",
        password: "hello-123-qw!)",
        database: "postgres",
        tls: .prefer(sslContext)
    )


    try app.databases.use(
        .postgres(configuration: config, connectionPoolTimeout: .seconds(5)),
        as: .psql
    )


    app.migrations.add(CreateUser())
    app.migrations.add(CreateProduct())
    app.migrations.add(SeedProducts())// таблица users
    app.migrations.add(CreateOrder())   // таблица orders (покупки)
    app.migrations.add(CreateLog())
    try await app.autoMigrate()

    app.sessions.configuration.cookieFactory = { session in
        .init(string: session.string, maxAge: 60 * 60 * 24 * 30, isHTTPOnly: true)
    }
    app.middleware.use(app.sessions.middleware)

    app.views.use(.leaf)

    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.routes.defaultMaxBodySize = "20mb"
    
    try routes(app)
}
