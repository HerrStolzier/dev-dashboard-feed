import Foundation
import Testing
@testable import DevDashboardFeed

@Test func projectRepoStorePersistsConfiguredRepos() async throws {
    let storeURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("repos.json")
    let repo = ProjectRepo(
        id: UUID(),
        name: "turboquant",
        path: "/tmp/turboquant",
        accentColor: "#38bdf8",
        isActive: true,
        lastSuccessfulCrawlAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
    let store = ProjectRepoStore(storeURL: storeURL)

    try store.save([repo])

    let restored = try store.load()
    #expect(restored == [repo])
}

@Test func gitActivityScannerReadsCommitsSinceDate() async throws {
    let repoURL = try makeTemporaryGitRepo()
    try runGit(["config", "user.name", "Devboard Test"], in: repoURL)
    try runGit(["config", "user.email", "devboard@example.test"], in: repoURL)
    try write("first", to: repoURL.appendingPathComponent("first.txt"))
    try runGit(["add", "."], in: repoURL)
    try runGit(["commit", "-m", "Initial baseline", "--date", "2026-04-28T10:00:00Z"], in: repoURL)
    let cutoff = Date(timeIntervalSince1970: 1_777_376_400)

    try write("daily", to: repoURL.appendingPathComponent("daily.txt"))
    try runGit(["add", "."], in: repoURL)
    try runGit(["commit", "-m", "Add daily digest input", "--date", "2026-04-29T19:05:00Z"], in: repoURL)

    let repo = ProjectRepo(
        id: UUID(),
        name: "digest-repo",
        path: repoURL.path,
        accentColor: "#a78bfa",
        isActive: true,
        lastSuccessfulCrawlAt: cutoff
    )
    let activity = try GitActivityScanner().activity(for: repo, since: cutoff)

    #expect(activity.repo == repo)
    #expect(activity.commits.map(\.subject) == ["Add daily digest input"])
    #expect(activity.commits.first?.changedFiles == ["daily.txt"])
}

@Test func dailyDigestRendererCreatesTurboQuantStyleHTML() async throws {
    let repo = ProjectRepo(
        id: UUID(),
        name: "kurier",
        path: "/tmp/kurier",
        accentColor: "#34d399",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )
    let activity = GitRepoActivity(
        repo: repo,
        commits: [
            GitCommitActivity(
                hash: "abcdef123456",
                shortHash: "abcdef1",
                subject: "Add project timeline",
                authorName: "Devboard Test",
                authoredAt: Date(timeIntervalSince1970: 1_777_461_900),
                changedFiles: ["Sources/Timeline.swift", "Tests/TimelineTests.swift"]
            )
        ]
    )

    let html = DailyDigestRenderer().render(activity: activity, generatedAt: Date(timeIntervalSince1970: 1_777_464_000))

    #expect(html.contains("background: #0a0a0f"))
    #expect(html.contains("linear-gradient(135deg, #38bdf8, #a78bfa, #34d399)"))
    #expect(html.contains("class=\"badge tech\""))
    #expect(html.contains("class=\"explainer\""))
    #expect(html.contains("class=\"phase verified\""))
    #expect(html.contains("Add project timeline"))
    #expect(html.contains("Sources/Timeline.swift"))
}

@MainActor
@Test func appModelGeneratesDigestDocumentForActiveRepo() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let outputRoot = tempRoot.appendingPathComponent("digests", isDirectory: true)
    let storeURL = tempRoot.appendingPathComponent("repos.json")
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let repo = ProjectRepo(
        id: UUID(),
        name: "timeline",
        path: "/tmp/timeline",
        accentColor: "#38bdf8",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )
    let scanner = FakeGitActivityScanner(
        activity: GitRepoActivity(
            repo: repo,
            commits: [
                GitCommitActivity(
                    hash: "1234567890",
                    shortHash: "1234567",
                    subject: "Ship colorful digest",
                    authorName: "Devboard Test",
                    authoredAt: Date(timeIntervalSince1970: 1_777_461_900),
                    changedFiles: ["Sources/Digest.swift"]
                )
            ]
        )
    )
    let appModel = AppModel(
        folderAccessController: DigestFakeFolderAccessController(),
        documentScanner: DocumentScanner(),
        projectRepoStore: ProjectRepoStore(storeURL: storeURL),
        gitActivityScanner: scanner,
        digestOutputRoot: outputRoot,
        launchOverrides: LaunchOverrides(arguments: ["DevDashboardFeed"], fileManager: fileManager)
    )

    try appModel.addProjectRepo(repo)
    let results = appModel.runDailyDigestsForTesting(now: Date(timeIntervalSince1970: 1_777_464_000))

    #expect(results == [.created(repoName: "timeline", commitCount: 1)])
    #expect(appModel.documents.contains { $0.sourceKind == .dailyDigest && $0.title.contains("timeline") })
    #expect(appModel.documents.first(where: { $0.sourceKind == .dailyDigest })?.accentColor == "#38bdf8")
}

private func makeTemporaryGitRepo() throws -> URL {
    let repoURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: repoURL, withIntermediateDirectories: true)
    try runGit(["init"], in: repoURL)
    return repoURL
}

private func write(_ text: String, to url: URL) throws {
    try Data(text.utf8).write(to: url)
}

@discardableResult
private func runGit(_ arguments: [String], in directory: URL) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments
    process.currentDirectoryURL = directory

    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    try process.run()
    process.waitUntilExit()

    let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    if process.terminationStatus != 0 {
        let errorText = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        throw NSError(domain: "GitTest", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorText])
    }

    return outputText
}

private struct FakeGitActivityScanner: GitActivityScanning {
    let activity: GitRepoActivity

    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity {
        activity
    }
}

@MainActor
private final class DigestFakeFolderAccessController: FolderAccessControlling {
    let restoredFolders: [WatchedFolder]

    init(restoredFolders: [WatchedFolder] = []) {
        self.restoredFolders = restoredFolders
    }

    func restoreWatchedFolders() -> [WatchedFolder] {
        restoredFolders
    }

    func chooseFolder(existingFolders: [WatchedFolder]) throws -> FolderSelectionResult {
        .cancelled
    }

    func removeFolder(_ folder: WatchedFolder, from existingFolders: [WatchedFolder]) -> [WatchedFolder] {
        existingFolders.filter { $0.id != folder.id }
    }
}
