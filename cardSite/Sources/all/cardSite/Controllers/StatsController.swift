import Vapor
import Fluent

struct LogDTO: Content {
    let action: String
    let page: String
    let time: String
}

struct StatsResponse: Content {
    let totalLogs: Int
    let totalToday: Int
    let totalUsers: Int
    let totalOrders: Int
    let totalRevenue: Int
    let lastLogs: [LogDTO]
    let chartLabels: [String]
    let chartData: [Int]
    let donutLabels: [String] // Для пончика
    let donutData: [Int]
}

struct StatsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let stats = routes.grouped(RequireAuthMiddleware()).grouped("admin", "stats")
        stats.get(use: page)
        stats.get("data", use: api)
    }

    func page(req: Request) async throws -> View {
        return try await req.view.render("stats")
    }

    func api(req: Request) async throws -> Response {
        let logs = try await Log.query(on: req.db).sort(\.$createdAt, .descending).limit(200).all()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"

        let logDTOs = logs.map { log in
            let time = log.createdAt != nil ? formatter.string(from: log.createdAt!) : "-"
            return LogDTO(action: log.action, page: log.page, time: time)
        }

        var groupByDay: [String: Int] = [:]
        for log in logs {
            if let date = log.createdAt {
                let day = dateFormatter.string(from: date)
                groupByDay[day, default: 0] += 1
            }
        }
        let sortedDays = groupByDay.keys.sorted()

        // ДЛЯ ПОНЧИКА: Берем только первую часть до двоеточия (например, "В корзину")
        var actionTypes: [String: Int] = [:]
        for log in logs {
            var shortAction = log.action.components(separatedBy: ":").first ?? log.action
            if shortAction.count > 20 { shortAction = String(shortAction.prefix(20)) + "..." }
            actionTypes[shortAction, default: 0] += 1
        }
        
        let sortedActions = actionTypes.sorted { $0.value > $1.value }.prefix(4)
        let donutLabels = sortedActions.map { $0.key }
        let donutData = sortedActions.map { $0.value }

        let totalUsers = try await User.query(on: req.db).count()
        let totalOrders = try await Order.query(on: req.db).count()
        let allOrders = try await Order.query(on: req.db).all()
        let totalRevenue = allOrders.reduce(0) { $0 + $1.total }

        let response = StatsResponse(
            totalLogs: logs.count,
            totalToday: groupByDay[dateFormatter.string(from: Date())] ?? 0,
            totalUsers: totalUsers,
            totalOrders: totalOrders,
            totalRevenue: totalRevenue,
            lastLogs: logDTOs,
            chartLabels: sortedDays,
            chartData: sortedDays.map { groupByDay[$0] ?? 0 },
            donutLabels: donutLabels,
            donutData: donutData
        )

        return try await response.encodeResponse(for: req)
    }
}
