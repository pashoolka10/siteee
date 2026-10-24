import Vapor

struct RequireAuthMiddleware: AsyncMiddleware {

    func respond(to req: Request, chainingTo next: any AsyncResponder) async throws -> Response {

        guard req.session.data["user_id"] != nil else {
            return req.redirect(to: "/?need_auth=1")
        }

        return try await next.respond(to: req)
    }
}
