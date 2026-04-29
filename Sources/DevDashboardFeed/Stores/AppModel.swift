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
    let preferredDocumentSelectionID: DocumentItem.ID?

    @ObservationIgnored
    private let folderAccessController: any FolderAccessControlling
    @ObservationIgnored
    private let documentScanner: any DocumentScanning
    @ObservationIgnored
    private let projectRepoStore: ProjectRepoStore
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

    init(
        folderAccessController: any FolderAccessControlling = FolderAccessManager.shared,
        documentScanner: any DocumentScanning = DocumentScanner(),
        projectRepoStore: ProjectRepoStore = ProjectRepoStore(),
        gitActivityScanner: any GitActivityScanning = GitActivityScanner(),
        dailyDigestRenderer: DailyDigestRenderer = DailyDigestRenderer(),
        digestOutputRoot: URL = AppModel.defaultDigestOutputRoot(),
        fileManager: FileManager = .default,
        launchOverrides: LaunchOverrides = LaunchOverrides(),
        digestScheduler: DigestScheduler = DigestScheduler()
    ) {
        self.folderAccessController = folderAccessController
        self.documentScanner = documentScanner
        self.projectRepoStore = projectRepoStore
        self.gitActivityScanner = gitActivityScanner
        self.dailyDigestRenderer = dailyDigestRenderer
        self.digestOutputRoot = digestOutputRoot
        self.fileManager = fileManager
        self.digestScheduler = digestScheduler
        self.preferredDocumentSelectionID = launchOverrides.preferredDocumentSelectionID
        self.folderStatusMessage = nil
        self.digestStatusMessage = nil
        self.documents = []
        self.projectRepos = (try? projectRepoStore.load()) ?? []
        self.watchedFolders = launchOverrides.watchedFoldersOverride ?? folderAccessController.restoreWatchedFolders()
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
            try addProjectRepo(
                ProjectRepo(
                    id: UUID(),
                    name: selectedURL.lastPathComponent,
                    path: normalizedPath,
                    accentColor: nextAccentColor(),
                    isActive: true,
                    lastSuccessfulCrawlAt: nil
                )
            )
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

    @discardableResult
    func runDailyDigests(now: Date = .now) -> [DigestRunResult] {
        guard !projectRepos.isEmpty else {
            digestStatusMessage = "No project repos are configured yet."
            return []
        }

        var results: [DigestRunResult] = []

        for index in projectRepos.indices {
            guard projectRepos[index].isActive else {
                results.append(.skipped(repoName: projectRepos[index].name))
                continue
            }

            let repo = projectRepos[index]
            do {
                let crawlStart = repo.lastSuccessfulCrawlAt ?? Calendar.current.startOfDay(for: now)
                let activity = try gitActivityScanner.activity(for: repo, since: crawlStart)

                guard !activity.commits.isEmpty else {
                    projectRepos[index].lastSuccessfulCrawlAt = now
                    results.append(.skipped(repoName: repo.name))
                    continue
                }

                let html = dailyDigestRenderer.render(activity: activity, generatedAt: now)
                let digestURL = digestFileURL(for: repo, date: now)
                try fileManager.createDirectory(at: digestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(html.utf8).write(to: digestURL, options: .atomic)
                projectRepos[index].lastSuccessfulCrawlAt = now
                results.append(.created(repoName: repo.name, commitCount: activity.commits.count))
            } catch {
                results.append(.failed(repoName: repo.name, message: error.localizedDescription))
            }
        }

        do {
            try projectRepoStore.save(projectRepos)
        } catch {
            results.append(.failed(repoName: "Project Repo Store", message: error.localizedDescription))
        }

        digestStatusMessage = makeDigestStatusMessage(from: results)
        reloadDocuments()
        return results
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
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("DailyDigests", isDirectory: true)
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
            let digestDirectoryName = Self.digestDirectoryName(for: repo)
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

    private func digestFileURL(for repo: ProjectRepo, date: Date) -> URL {
        digestOutputRoot
            .appendingPathComponent(Self.digestDirectoryName(for: repo), isDirectory: true)
            .appendingPathComponent("\(DateFormatter.devboardFileDay.string(from: date)).html")
    }

    private func updateCatchUpStatus(now: Date) {
        guard !projectRepos.isEmpty else {
            return
        }

        let lastRun = projectRepos.compactMap(\.lastSuccessfulCrawlAt).max()
        if digestScheduler.missedScheduledRun(lastSuccessfulRunAt: lastRun, now: now) != nil {
            digestStatusMessage = "A scheduled 20:00 digest run was missed. You can run Daily Digests now to catch up."
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

    private static func digestDirectoryName(for repo: ProjectRepo) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = repo.name.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let cleaned = String(scalars)
            .split(separator: "-")
            .joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        let stableName = cleaned.isEmpty ? "repo" : cleaned
        return "\(stableName)-\(repo.id.uuidString.prefix(8))"
    }
}

extension DateFormatter {
    static let devboardFileDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
