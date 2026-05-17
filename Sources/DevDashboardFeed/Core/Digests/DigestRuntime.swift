import Foundation

struct DigestRuntime {
    let projectRepoStore: ProjectRepoStore
    let metadataStore: DigestRunMetadataStore
    let historyStore: DigestRunHistoryStore
    let runLock: DigestRunLock
    let scanner: any GitActivityScanning
    let renderer: DailyDigestRenderer
    let digestOutputRoot: URL
    let fileManager: FileManager

    init(
        projectRepoStore: ProjectRepoStore = ProjectRepoStore(),
        metadataStore: DigestRunMetadataStore = DigestRunMetadataStore(),
        historyStore: DigestRunHistoryStore = DigestRunHistoryStore(),
        runLock: DigestRunLock = DigestRunLock(),
        scanner: any GitActivityScanning = GitActivityScanner(),
        renderer: DailyDigestRenderer = DailyDigestRenderer(),
        digestOutputRoot: URL = DigestRuntime.defaultDigestOutputRoot(),
        fileManager: FileManager = .default
    ) {
        self.projectRepoStore = projectRepoStore
        self.metadataStore = metadataStore
        self.historyStore = historyStore
        self.runLock = runLock
        self.scanner = scanner
        self.renderer = renderer
        self.digestOutputRoot = digestOutputRoot
        self.fileManager = fileManager
    }

    static func defaultDigestOutputRoot(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("DailyDigests", isDirectory: true)
    }

    static func defaultLogDirectory(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
    }
}
