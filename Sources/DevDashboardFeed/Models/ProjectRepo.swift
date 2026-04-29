import Foundation

struct ProjectRepo: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var accentColor: String
    var isActive: Bool
    var lastSuccessfulCrawlAt: Date?
}

extension ProjectRepo {
    static let defaultAccentColors = [
        "#38bdf8",
        "#a78bfa",
        "#34d399",
        "#fbbf24",
        "#f472b6",
        "#fb923c",
    ]
}
