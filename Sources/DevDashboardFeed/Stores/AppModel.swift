import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var documents: [DocumentItem]
    var watchedFolders: [WatchedFolder]
    var projectRepos: [ProjectRepo]
    var folderStatusMessage: String?
    var digestStatusMessage: String?
    var backgroundAgentStatusMessage: String?
    var digestRunMetadata: DigestRunMetadata
    var missedScheduledRunAt: Date?
    var isDigestRunInProgress: Bool
    let preferredDocumentSelectionID: DocumentItem.ID?

    @ObservationIgnored
    private let folderAccessController: any FolderAccessControlling
    @ObservationIgnored
    private let documentScanner: any DocumentScanning
    @ObservationIgnored
    private let projectRepoStore: ProjectRepoStore
    @ObservationIgnored
    private let metadataStore: DigestRunMetadataStore
    @ObservationIgnored
    private let gitActivityScanner: any GitActivityScanning
    @ObservationIgnored
    private let dailyDigestRenderer: DailyDigestRenderer
    @ObservationIgnored
    private let digestScheduler: DigestScheduler
    @ObservationIgnored
    private let digestOutputRoot: URL
    @ObservationIgnored
    private let fileManager: FileManager
    @ObservationIgnored
    private let projectRepoAccess: ProjectRepoAccess
    @ObservationIgnored
    private let backgroundService: DigestBackgroundService
    @ObservationIgnored
    private var activeProjectRepoURLs: [UUID: URL]

    init(
        folderAccessController: any FolderAccessControlling = FolderAccessManager.shared,
        documentScanner: any DocumentScanning = DocumentScanner(),
        projectRepoStore: ProjectRepoStore = ProjectRepoStore(),
        metadataStore: DigestRunMetadataStore = DigestRunMetadataStore(),
        gitActivityScanner: any GitActivityScanning = GitActivityScanner(),
        dailyDigestRenderer: DailyDigestRenderer = DailyDigestRenderer(),
        digestOutputRoot: URL = AppModel.defaultDigestOutputRoot(),
        fileManager: FileManager = .default,
        launchOverrides: LaunchOverrides = LaunchOverrides(),
        digestScheduler: DigestScheduler = DigestScheduler(),
        projectRepoAccess: ProjectRepoAccess = ProjectRepoAccess(),
        backgroundService: DigestBackgroundService = DigestBackgroundService()
    ) {
        self.folderAccessController = folderAccessController
        self.documentScanner = documentScanner
        self.projectRepoStore = projectRepoStore
        self.metadataStore = metadataStore
        self.gitActivityScanner = gitActivityScanner
        self.dailyDigestRenderer = dailyDigestRenderer
        self.digestOutputRoot = digestOutputRoot
        self.fileManager = fileManager
        self.projectRepoAccess = projectRepoAccess
        self.backgroundService = backgroundService
        self.digestScheduler = digestScheduler
        self.preferredDocumentSelectionID = launchOverrides.preferredDocumentSelectionID
        let restoredProjectRepos = projectRepoAccess.restore((try? projectRepoStore.load()) ?? [])
        var loadedMetadata = (try? metadataStore.load()) ?? .empty
        loadedMetadata.nextScheduledRunAt = digestScheduler.nextScheduledRun(after: .now)

        self.folderStatusMessage = nil
        self.digestStatusMessage = nil
        self.backgroundAgentStatusMessage = nil
        self.digestRunMetadata = loadedMetadata
        self.missedScheduledRunAt = nil
        self.isDigestRunInProgress = false
        self.documents = []
        self.projectRepos = restoredProjectRepos.repos
        self.activeProjectRepoURLs = restoredProjectRepos.activeURLs
        self.watchedFolders = launchOverrides.watchedFoldersOverride ?? folderAccessController.restoreWatchedFolders()
        try? projectRepoStore.save(projectRepos)
        updateCatchUpStatus(now: .now)
        reloadDocuments()
    }

    func chooseWatchedFolder() {
        do {
            let selectionResult = try folderAccessController.chooseFolder(existingFolders: watchedFolders)

            switch selectionResult {
            case .added(let folder, let updatedFolders):
                watchedFolders = updatedFolders
                folderStatusMessage = "\"\(folder.name)\" was added."
                reloadDocuments()
            case .alreadyAdded(let folder):
                folderStatusMessage = "\"\(folder.name)\" is already in the list."
            case .cancelled:
                break
            }
        } catch {
            folderStatusMessage = error.localizedDescription
        }
    }

    func removeWatchedFolder(_ folder: WatchedFolder) {
        watchedFolders = folderAccessController.removeFolder(folder, from: watchedFolders)
        folderStatusMessage = "\"\(folder.name)\" was removed."
        reloadDocuments()
    }

    func chooseProjectRepo() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Project Repo"
        panel.message = "Pick a local Git repository. Devboard will create daily digest posts from committed Git activity."
        panel.prompt = "Choose Repo"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        let normalizedPath = selectedURL.standardizedFileURL.path
        guard !projectRepos.contains(where: { $0.path == normalizedPath }) else {
            digestStatusMessage = "\"\(selectedURL.lastPathComponent)\" is already configured."
            return
        }

        guard isGitRepository(at: normalizedPath) else {
            digestStatusMessage = "\"\(selectedURL.lastPathComponent)\" is not a Git repository."
            return
        }

        do {
            let bookmarkData = try projectRepoAccess.makeBookmarkData(for: selectedURL)
            let startedSecurityScope = selectedURL.startAccessingSecurityScopedResource()
            let repo = ProjectRepo(
                id: UUID(),
                name: selectedURL.lastPathComponent,
                path: normalizedPath,
                accentColor: nextAccentColor(),
                isActive: true,
                lastSuccessfulCrawlAt: nil,
                bookmarkData: bookmarkData
            )

            try addProjectRepo(
                repo
            )
            if startedSecurityScope {
                activeProjectRepoURLs[repo.id] = selectedURL
            }
            digestStatusMessage = "\"\(selectedURL.lastPathComponent)\" is ready for Daily Digests."
        } catch {
            digestStatusMessage = error.localizedDescription
        }
    }

    func addProjectRepo(_ repo: ProjectRepo) throws {
        if let existingIndex = projectRepos.firstIndex(where: { $0.path == repo.path }) {
            projectRepos[existingIndex] = repo
        } else {
            projectRepos.append(repo)
        }

        projectRepos = sortProjectRepos(projectRepos)
        try projectRepoStore.save(projectRepos)
        reloadDocuments()
    }

    func removeProjectRepo(_ repo: ProjectRepo) {
        if let activeURL = activeProjectRepoURLs.removeValue(forKey: repo.id) {
            activeURL.stopAccessingSecurityScopedResource()
        }

        projectRepos.removeAll { $0.id == repo.id }
        do {
            try projectRepoStore.save(projectRepos)
            digestStatusMessage = "\"\(repo.name)\" was removed."
        } catch {
            digestStatusMessage = error.localizedDescription
        }
        reloadDocuments()
    }

    func setProjectRepo(_ repo: ProjectRepo, isActive: Bool) {
        guard let index = projectRepos.firstIndex(where: { $0.id == repo.id }) else {
            return
        }

        projectRepos[index].isActive = isActive
        do {
            try projectRepoStore.save(projectRepos)
            digestStatusMessage = "\"\(repo.name)\" is now \(isActive ? "active" : "inactive")."
        } catch {
            digestStatusMessage = error.localizedDescription
        }
    }

    func runDailyDigests(now: Date = .now) {
        guard !isDigestRunInProgress else {
            digestStatusMessage = "Daily Digests are already running."
            return
        }

        guard !projectRepos.isEmpty else {
            digestStatusMessage = "No project repos are configured yet."
            return
        }

        isDigestRunInProgress = true
        digestStatusMessage = "Running Daily Digests..."

        let runner = DailyDigestRunner(
            repos: projectRepos,
            scanner: gitActivityScanner,
            renderer: dailyDigestRenderer,
            digestOutputRoot: digestOutputRoot
        )

        Task {
            let output = await Task.detached(priority: .userInitiated) {
                runner.run(now: now)
            }.value
            finishDigestRun(output, now: now)
        }
    }

    var isBackgroundAgentInstalled: Bool {
        backgroundService.status == .installed
    }

    func installBackgroundAgent() {
        guard let executableURL = Bundle.main.executableURL else {
            backgroundAgentStatusMessage = "Devboard could not find its executable for the background agent."
            return
        }

        do {
            let plistURL = try backgroundService.install(executableURL: executableURL)
            backgroundAgentStatusMessage = "Daily Digest agent installed at \(plistURL.path)."
        } catch {
            backgroundAgentStatusMessage = error.localizedDescription
        }
    }

    func uninstallBackgroundAgent() {
        do {
            try backgroundService.uninstall()
            backgroundAgentStatusMessage = "Daily Digest agent was removed."
        } catch {
            backgroundAgentStatusMessage = error.localizedDescription
        }
    }

    func kickstartBackgroundAgent() {
        do {
            try backgroundService.kickstart()
            backgroundAgentStatusMessage = "Daily Digest agent was started once."
        } catch {
            backgroundAgentStatusMessage = error.localizedDescription
        }
    }

    @discardableResult
    func runDailyDigestsForTesting(now: Date = .now) -> [DigestRunResult] {
        let runner = DailyDigestRunner(
            repos: projectRepos,
            scanner: gitActivityScanner,
            renderer: dailyDigestRenderer,
            digestOutputRoot: digestOutputRoot
        )

        return finishDigestRun(runner.run(now: now), now: now)
    }

    func reloadDocuments() {
        let scannedDocuments = documentScanner.scanDocuments(in: watchedFolders, sourceKind: .htmlArtifact)
        let digestDocuments = decoratedDigestDocuments()
        let combinedDocuments = (scannedDocuments + digestDocuments)
            .sorted { $0.modifiedAt > $1.modifiedAt }

        if combinedDocuments.isEmpty && watchedFolders.isEmpty && projectRepos.isEmpty {
            documents = DocumentItem.sampleItems
        } else {
            documents = combinedDocuments
        }
    }

    static func defaultDigestOutputRoot(fileManager: FileManager = .default) -> URL {
        DigestRuntime.defaultDigestOutputRoot(fileManager: fileManager)
    }

    private func decoratedDigestDocuments() -> [DocumentItem] {
        guard fileManager.fileExists(atPath: digestOutputRoot.path) else {
            return []
        }

        let digestFolder = WatchedFolder(
            id: UUID(uuidString: "C4472A30-5388-4E64-8AB7-0C0EA105EC9D") ?? UUID(),
            name: "Daily Digests",
            path: digestOutputRoot.path,
            bookmarkData: Data(),
            isAccessible: true
        )

        return documentScanner
            .scanDocuments(in: [digestFolder], sourceKind: .dailyDigest)
            .map(decorateDigestDocument)
    }

    private func decorateDigestDocument(_ document: DocumentItem) -> DocumentItem {
        let normalizedPath = document.path.replacingOccurrences(of: "\\", with: "/")
        let matchingRepo = projectRepos.first { repo in
            let digestDirectoryName = DigestPath.directoryName(for: repo)
            return normalizedPath.hasPrefix(digestDirectoryName + "/")
                || document.title.localizedCaseInsensitiveContains(repo.name)
                || document.absolutePath?.contains("/\(digestDirectoryName)/") == true
        }

        return DocumentItem(
            id: document.id,
            title: document.title,
            project: matchingRepo?.name ?? document.project,
            path: document.path,
            absolutePath: document.absolutePath,
            previewRootPath: document.previewRootPath,
            summary: document.summary,
            explainer: document.explainer,
            relativeTimestamp: document.relativeTimestamp,
            modifiedAt: document.modifiedAt,
            sourceKind: .dailyDigest,
            accentColor: matchingRepo?.accentColor,
            generatedAt: document.generatedAt
        )
    }

    private func updateCatchUpStatus(now: Date) {
        guard !projectRepos.isEmpty else {
            return
        }

        let lastRun = digestRunMetadata.lastSuccessfulRunAt
            ?? projectRepos.compactMap(\.lastSuccessfulCrawlAt).max()
        if let missedRun = digestScheduler.missedScheduledRun(lastSuccessfulRunAt: lastRun, now: now) {
            missedScheduledRunAt = missedRun
            digestStatusMessage = "The scheduled 20:00 digest from \(DateFormatter.devboardDayAndTime.string(from: missedRun)) was missed. You can run Daily Digests now to catch up."
        } else {
            missedScheduledRunAt = nil
        }
    }

    private func makeDigestStatusMessage(from results: [DigestRunResult]) -> String {
        let created = results.reduce(0) { partial, result in
            if case .created = result {
                return partial + 1
            }
            return partial
        }
        let failed = results.reduce(0) { partial, result in
            if case .failed = result {
                return partial + 1
            }
            return partial
        }

        if created > 0 && failed == 0 {
            return "Created \(created) Daily Digest post\(created == 1 ? "" : "s")."
        }

        if created > 0 {
            return "Created \(created) Daily Digest post\(created == 1 ? "" : "s"), \(failed) failed."
        }

        if failed > 0 {
            return "\(failed) Daily Digest run\(failed == 1 ? "" : "s") failed."
        }

        return "No new committed Git activity was found."
    }

    @discardableResult
    private func finishDigestRun(_ output: DailyDigestRunOutput, now: Date = .now) -> [DigestRunResult] {
        var results = output.results
        projectRepos = sortProjectRepos(output.updatedRepos)

        do {
            try projectRepoStore.save(projectRepos)
        } catch {
            results.append(.failed(repoName: "Project Repo Store", message: error.localizedDescription))
        }

        digestStatusMessage = makeDigestStatusMessage(from: results)
        isDigestRunInProgress = false
        updateDigestRunMetadata(after: results, now: now)
        reloadDocuments()
        return results
    }

    private func updateDigestRunMetadata(after results: [DigestRunResult], now: Date = .now) {
        let failures = results.compactMap { result -> String? in
            if case .failed(let repoName, let message) = result {
                return "\(repoName): \(message)"
            }
            return nil
        }

        digestRunMetadata.lastRunAt = now
        digestRunMetadata.lastErrorMessage = failures.isEmpty ? nil : failures.joined(separator: "\n")
        digestRunMetadata.nextScheduledRunAt = digestScheduler.nextScheduledRun(after: now)

        if failures.isEmpty {
            digestRunMetadata.lastSuccessfulRunAt = now
            missedScheduledRunAt = nil
        }

        do {
            try metadataStore.save(digestRunMetadata)
        } catch {
            digestStatusMessage = "\(digestStatusMessage ?? "Daily Digest run finished.") Metadata could not be saved: \(error.localizedDescription)"
        }
    }

    private func isGitRepository(at path: String) -> Bool {
        let gitURL = URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(".git")
        if fileManager.fileExists(atPath: gitURL.path) {
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path, "rev-parse", "--is-inside-work-tree"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        guard process.terminationStatus == 0 else {
            return false
        }

        let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return outputText.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    private func nextAccentColor() -> String {
        let colors = ProjectRepo.defaultAccentColors
        guard !colors.isEmpty else {
            return "#38bdf8"
        }

        return colors[projectRepos.count % colors.count]
    }

    private func sortProjectRepos(_ repos: [ProjectRepo]) -> [ProjectRepo] {
        repos.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

}

extension DateFormatter {
    static let devboardFileDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func devboardFileDayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static let devboardDayAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
