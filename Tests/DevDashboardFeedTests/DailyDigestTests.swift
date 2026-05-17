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

@MainActor
@Test func digestRuntimeUsesSharedDefaultPaths() async throws {
    let fileManager = FileManager.default

    #expect(AppModel.defaultDigestOutputRoot(fileManager: fileManager) == DigestRuntime.defaultDigestOutputRoot(fileManager: fileManager))
    #expect(ProjectRepoStore.defaultStoreURL(fileManager: fileManager).lastPathComponent == "project-repos.json")
    #expect(DigestRuntime.defaultLogDirectory(fileManager: fileManager).path.contains("DevDashboardFeed/Logs"))
}

@Test func digestRunMetadataStorePersistsRunState() async throws {
    let storeURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("metadata.json")
    let store = DigestRunMetadataStore(storeURL: storeURL)
    let metadata = DigestRunMetadata(
        lastRunAt: Date(timeIntervalSince1970: 1_778_096_800),
        lastSuccessfulRunAt: Date(timeIntervalSince1970: 1_778_096_800),
        lastErrorMessage: nil,
        nextScheduledRunAt: Date(timeIntervalSince1970: 1_778_183_200)
    )

    try store.save(metadata)

    #expect(try store.load() == metadata)
}

@Test func digestRunHistoryStoreKeepsLatestEntries() async throws {
    let storeURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("history.json")
    let store = DigestRunHistoryStore(storeURL: storeURL, limit: 2)

    try store.append(
        results: [
            .created(repoName: "one", commitCount: 1),
            .failed(repoName: "two", message: "boom"),
            .skipped(repoName: "three"),
        ],
        runAt: Date(timeIntervalSince1970: 1_778_096_800),
        source: .agent
    )

    let history = try store.load()
    #expect(history.entries.map(\.repoName) == ["two", "three"])
    #expect(history.entries.map(\.outcome) == [.failed, .skipped])
    #expect(history.entries.first?.errorMessage == "boom")
}

@Test func digestRunLockRejectsConcurrentRuns() async throws {
    let lockURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("digest.lock")
    let lock = DigestRunLock(lockURL: lockURL)

    _ = try lock.withLock {
        #expect(throws: DigestRunLockError.alreadyRunning) {
            try lock.withLock {}
        }
    }
}

@Test func gitActivityScannerTimesOutHungGitProcess() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    let fakeGit = tempRoot.appendingPathComponent("fake-git.sh")
    try Data("#!/bin/sh\nsleep 2\n".utf8).write(to: fakeGit)
    try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeGit.path)
    let repo = ProjectRepo(
        id: UUID(),
        name: "hung",
        path: tempRoot.path,
        accentColor: "#38bdf8",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )

    let scanner = GitActivityScanner(gitPath: fakeGit.path, timeout: 0.1)

    #expect(throws: GitActivityScannerError.gitTimedOut("rev-parse --is-inside-work-tree")) {
        _ = try scanner.activity(for: repo, since: nil)
    }
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
        historyStore: DigestRunHistoryStore(
            storeURL: tempRoot.appendingPathComponent("history.json")
        ),
        runLock: DigestRunLock(lockURL: tempRoot.appendingPathComponent("digest.lock")),
        gitActivityScanner: scanner,
        digestOutputRoot: outputRoot,
        launchOverrides: LaunchOverrides(arguments: ["DevDashboardFeed"], fileManager: fileManager)
    )

    try appModel.addProjectRepo(repo)
    let results = appModel.runDailyDigestsForTesting(now: Date(timeIntervalSince1970: 1_777_464_000))

    #expect(results == [.created(repoName: "timeline", commitCount: 1)])
    #expect(appModel.digestRunHistory.entries.first?.repoName == "timeline")
    #expect(appModel.digestRunHistory.entries.first?.outcome == .created)
    #expect(appModel.documents.contains { $0.sourceKind == .dailyDigest && $0.title.contains("timeline") })
    #expect(appModel.documents.first(where: { $0.sourceKind == .dailyDigest })?.accentColor == "#38bdf8")
}

@MainActor
@Test func appModelRefreshesDigestStateWrittenByExternalAgent() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let outputRoot = tempRoot.appendingPathComponent("digests", isDirectory: true)
    let storeURL = tempRoot.appendingPathComponent("repos.json")
    let metadataURL = tempRoot.appendingPathComponent("metadata.json")
    let historyURL = tempRoot.appendingPathComponent("history.json")
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let repo = ProjectRepo(
        id: UUID(),
        name: "agent-flow",
        path: "/tmp/agent-flow",
        accentColor: "#34d399",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )
    let repoStore = ProjectRepoStore(storeURL: storeURL)
    let metadataStore = DigestRunMetadataStore(storeURL: metadataURL)
    try repoStore.save([repo])

    let appModel = AppModel(
        folderAccessController: DigestFakeFolderAccessController(),
        documentScanner: DocumentScanner(),
        projectRepoStore: repoStore,
        metadataStore: metadataStore,
        historyStore: DigestRunHistoryStore(
            storeURL: historyURL
        ),
        runLock: DigestRunLock(lockURL: tempRoot.appendingPathComponent("digest.lock")),
        gitActivityScanner: FakeGitActivityScanner(
            activity: GitRepoActivity(repo: repo, commits: [])
        ),
        digestOutputRoot: outputRoot,
        launchOverrides: LaunchOverrides(arguments: ["DevDashboardFeed"], fileManager: fileManager),
        backgroundService: FakeDigestBackgroundService()
    )

    let runDate = Date(timeIntervalSince1970: 1_778_096_800)
    let updatedRepo = ProjectRepo(
        id: repo.id,
        name: repo.name,
        path: repo.path,
        accentColor: repo.accentColor,
        isActive: repo.isActive,
        lastSuccessfulCrawlAt: runDate,
        bookmarkData: repo.bookmarkData
    )
    let activity = GitRepoActivity(
        repo: updatedRepo,
        commits: [
            GitCommitActivity(
                hash: "abcdef123456",
                shortHash: "abcdef1",
                subject: "External agent digest",
                authorName: "Devboard Test",
                authoredAt: runDate,
                changedFiles: ["Sources/AppModel.swift"]
            )
        ]
    )
    let digestURL = outputRoot
        .appendingPathComponent(DigestPath.directoryName(for: updatedRepo), isDirectory: true)
        .appendingPathComponent("\(DateFormatter.devboardFileDayString(from: runDate)).html")
    try fileManager.createDirectory(at: digestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(DailyDigestRenderer().render(activity: activity, generatedAt: runDate).utf8).write(to: digestURL)
    try repoStore.save([updatedRepo])
    try metadataStore.save(
        DigestRunMetadata(
            lastRunAt: runDate,
            lastSuccessfulRunAt: runDate,
            lastErrorMessage: nil,
            nextScheduledRunAt: Date(timeIntervalSince1970: 1_778_183_200)
        )
    )
    try DigestRunHistoryStore(storeURL: historyURL).append(
        results: [.created(repoName: "agent-flow", commitCount: 1)],
        runAt: runDate,
        source: .agent
    )

    let changed = appModel.refreshDigestStateFromStores(now: runDate)

    #expect(changed)
    #expect(appModel.digestRunMetadata.lastRunAt == runDate)
    #expect(appModel.digestRunHistory.entries.first?.repoName == "agent-flow")
    #expect(appModel.projectRepos.first?.lastSuccessfulCrawlAt == runDate)
    #expect(appModel.documents.contains { $0.sourceKind == .dailyDigest && $0.title.contains("agent-flow") })
}

@Test func dailyDigestCommandSavesUpdatedReposAndKeepsRepoFailuresLocal() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let outputRoot = tempRoot.appendingPathComponent("digests", isDirectory: true)
    let storeURL = tempRoot.appendingPathComponent("repos.json")
    let historyURL = tempRoot.appendingPathComponent("history.json")
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)

    let goodRepo = ProjectRepo(
        id: UUID(),
        name: "good",
        path: "/tmp/good",
        accentColor: "#38bdf8",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )
    let failingRepo = ProjectRepo(
        id: UUID(),
        name: "failing",
        path: "/tmp/failing",
        accentColor: "#f472b6",
        isActive: true,
        lastSuccessfulCrawlAt: nil
    )
    let store = ProjectRepoStore(storeURL: storeURL)
    try store.save([goodRepo, failingRepo])
    let command = DailyDigestCommand(
        runtime: DigestRuntime(
            projectRepoStore: store,
            metadataStore: DigestRunMetadataStore(
                storeURL: tempRoot.appendingPathComponent("metadata.json")
            ),
            historyStore: DigestRunHistoryStore(storeURL: historyURL),
            runLock: DigestRunLock(lockURL: tempRoot.appendingPathComponent("digest.lock")),
            scanner: ConditionalGitActivityScanner(
                activity: GitRepoActivity(
                    repo: goodRepo,
                    commits: [
                        GitCommitActivity(
                            hash: "abcdef1234",
                            shortHash: "abcdef1",
                            subject: "Build command path",
                            authorName: "Devboard Test",
                            authoredAt: Date(timeIntervalSince1970: 1_778_096_700),
                            changedFiles: ["Sources/Command.swift"]
                        )
                    ]
                ),
                failingRepoID: failingRepo.id
            ),
            digestOutputRoot: outputRoot
        )
    )

    let result = command.run(now: Date(timeIntervalSince1970: 1_778_096_800))
    let restoredRepos = try store.load()
    let restoredMetadata = try DigestRunMetadataStore(
        storeURL: tempRoot.appendingPathComponent("metadata.json")
    ).load()
    let restoredHistory = try DigestRunHistoryStore(storeURL: historyURL).load()

    #expect(result.results.contains(.created(repoName: "good", commitCount: 1)))
    #expect(result.results.contains(.failed(repoName: "failing", message: "scanner failed")))
    #expect(result.exitCode == 1)
    #expect(restoredRepos.first(where: { $0.id == goodRepo.id })?.lastSuccessfulCrawlAt == Date(timeIntervalSince1970: 1_778_096_800))
    #expect(restoredRepos.first(where: { $0.id == failingRepo.id })?.lastSuccessfulCrawlAt == nil)
    #expect(restoredMetadata.lastRunAt == Date(timeIntervalSince1970: 1_778_096_800))
    #expect(restoredMetadata.lastSuccessfulRunAt == nil)
    #expect(restoredMetadata.lastErrorMessage == "failing: scanner failed")
    #expect(restoredMetadata.nextScheduledRunAt != nil)
    #expect(restoredHistory.entries.map(\.repoName).contains("good"))
    #expect(restoredHistory.entries.map(\.repoName).contains("failing"))
}

@Test func digestLaunchAgentPlistUsesEightPmCalendarInterval() async throws {
    let plist = DigestLaunchAgentPlist(
        executableURL: URL(fileURLWithPath: "/Applications/DevDashboardFeed.app/Contents/MacOS/DevDashboardFeed"),
        standardOutURL: URL(fileURLWithPath: "/tmp/devboard.out.log"),
        standardErrorURL: URL(fileURLWithPath: "/tmp/devboard.err.log")
    )
    let object = try PropertyListSerialization.propertyList(
        from: try plist.data(),
        options: [],
        format: nil
    )
    let dictionary = try #require(object as? [String: Any])
    let arguments = try #require(dictionary["ProgramArguments"] as? [String])
    let interval = try #require(dictionary["StartCalendarInterval"] as? [String: Int])
    let environment = try #require(dictionary["EnvironmentVariables"] as? [String: String])

    #expect(dictionary["Label"] as? String == DigestLaunchAgentInstaller.defaultLabel)
    #expect(arguments == [
        "/Applications/DevDashboardFeed.app/Contents/MacOS/DevDashboardFeed",
        "--run-digests-once",
        "--quiet",
    ])
    #expect(interval["Hour"] == 20)
    #expect(interval["Minute"] == 0)
    #expect(dictionary["StandardOutPath"] as? String == "/tmp/devboard.out.log")
    #expect(dictionary["StandardErrorPath"] as? String == "/tmp/devboard.err.log")
    #expect(environment == ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"])
}

@Test func digestLaunchAgentInstallerComputesOwnPlistPath() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let installer = DigestLaunchAgentInstaller(
        label: "com.example.devboard.test",
        launchAgentsDirectory: root.appendingPathComponent("LaunchAgents", isDirectory: true),
        logDirectory: root.appendingPathComponent("Logs", isDirectory: true)
    )

    #expect(installer.plistURL.path.hasSuffix("/LaunchAgents/com.example.devboard.test.plist"))
    #expect(installer.isInstalled == false)
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

private struct ConditionalGitActivityScanner: GitActivityScanning {
    let activity: GitRepoActivity
    let failingRepoID: UUID

    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity {
        if repo.id == failingRepoID {
            throw NSError(domain: "FakeScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "scanner failed"])
        }

        return GitRepoActivity(repo: repo, commits: activity.commits)
    }
}

private struct FakeDigestBackgroundService: DigestBackgroundServicing {
    var status: DigestBackgroundServiceStatus = .notInstalled
    var plistURL: URL = URL(fileURLWithPath: "/tmp/devboard-agent.plist")

    func install(executableURL: URL) throws -> URL {
        plistURL
    }

    func uninstall() throws {}

    func kickstart() throws {}
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
