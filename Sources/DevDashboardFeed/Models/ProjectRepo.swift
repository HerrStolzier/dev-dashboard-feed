import Foundation

struct ProjectRepo: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var path: String
    var accentColor: String
    var isActive: Bool
    var lastSuccessfulCrawlAt: Date?
    var bookmarkData: Data?

    init(
        id: UUID,
        name: String,
        path: String,
        accentColor: String,
        isActive: Bool,
        lastSuccessfulCrawlAt: Date?,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.accentColor = accentColor
        self.isActive = isActive
        self.lastSuccessfulCrawlAt = lastSuccessfulCrawlAt
        self.bookmarkData = bookmarkData
    }
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
