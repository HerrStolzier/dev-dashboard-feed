import Foundation

struct DigestRunMetadataStore {
    let storeURL: URL
    private let fileManager: FileManager

    init(
        storeURL: URL = DigestRunMetadataStore.defaultStoreURL(),
        fileManager: FileManager = .default
    ) {
        self.storeURL = storeURL
        self.fileManager = fileManager
    }

    func load() throws -> DigestRunMetadata {
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: storeURL)
        return try JSONDecoder.devboard.decode(DigestRunMetadata.self, from: data)
    }

    func save(_ metadata: DigestRunMetadata) throws {
        try fileManager.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.devboard.encode(metadata)
        try data.write(to: storeURL, options: .atomic)
    }

    static func defaultStoreURL(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("digest-run-metadata.json")
    }
}
