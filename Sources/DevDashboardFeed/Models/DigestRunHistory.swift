import Foundation

struct DigestRunHistory: Codable, Equatable, Sendable {
    var entries: [DigestRunHistoryEntry]

    static let empty = DigestRunHistory(entries: [])
}

struct DigestRunHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    enum Source: String, Codable, Sendable {
        case app
        case agent
        case cli
    }

    enum Outcome: String, Codable, Sendable {
        case created
        case skipped
        case failed
    }

    let id: UUID
    let runAt: Date
    let source: Source
    let repoName: String
    let outcome: Outcome
    let commitCount: Int?
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        runAt: Date,
        source: Source,
        repoName: String,
        outcome: Outcome,
        commitCount: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.runAt = runAt
        self.source = source
        self.repoName = repoName
        self.outcome = outcome
        self.commitCount = commitCount
        self.errorMessage = errorMessage
    }
}
