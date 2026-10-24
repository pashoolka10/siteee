import Vapor
import Fluent

func logAction(_ action: String, page: String, req: Request) {
    let userID = req.session.data["user_id"].flatMap { UUID(uuidString: $0) }
    let log = Log(action: action, page: page, userID: userID)
    
    // Сохраняем в фоне, чтобы не тормозить ответ пользователю
    Task {
        try? await log.save(on: req.db)
    }
}
