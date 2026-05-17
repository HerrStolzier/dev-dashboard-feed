import Foundation

struct DigestRunHistoryStore {
    let storeURL: URL
    let limit: Int
    private let fileManager: FileManager

    init(
        storeURL: URL = DigestRunHistoryStore.defaultStoreURL(),
        limit: Int = 100,
        fileManager: FileManager = .default
    ) {
        self.storeURL = storeURL
        self.limit = limit
        self.fileManager = fileManager
    }

    func load() throws -> DigestRunHistory {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: storeURL)
        return try JSONDecoder.devboard.decode(DigestRunHistory.self, from: data)
    }

    func append(results: [DigestRunResult], runAt: Date, source: DigestRunHistoryEntry.Source) throws {
        var history = (try? load()) ?? .empty
        history.entries.append(contentsOf: results.map { DigestRunHistoryEntry(result: $0, runAt: runAt, source: source) })
        if history.entries.count > limit {
            history.entries = Array(history.entries.suffix(limit))
        }
        try save(history)
    }

    func save(_ history: DigestRunHistory) throws {
        try fileManager.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.devboard.encode(history)
        try data.write(to: storeURL, options: .atomic)
    }

    static func defaultStoreURL(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("digest-run-history.json")
    }
}

extension DigestRunHistoryEntry {
    init(result: DigestRunResult, runAt: Date, source: Source) {
        switch result {
        case .created(let repoName, let commitCount):
            self.init(runAt: runAt, source: source, repoName: repoName, outcome: .created, commitCount: commitCount)
        case .skipped(let repoName):
            self.init(runAt: runAt, source: source, repoName: repoName, outcome: .skipped)
        case .failed(let repoName, let message):
            self.init(runAt: runAt, source: source, repoName: repoName, outcome: .failed, errorMessage: message)
        }
    }
}
