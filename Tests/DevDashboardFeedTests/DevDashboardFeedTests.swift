import Foundation
import Testing
import WebKit
@testable import DevDashboardFeed

@Test func sampleDocumentsExist() async throws {
    #expect(!DocumentItem.sampleItems.isEmpty)
}

@Test func scannerFindsHTMLFilesAndExtractsMetadata() async throws {
    let fixturesURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures", isDirectory: true)
    let folder = WatchedFolder(
        id: UUID(),
        name: "Fixtures",
        path: fixturesURL.path,
        bookmarkData: Data(),
        isAccessible: true
    )
    let scanner = DocumentScanner(now: Date(timeIntervalSince1970: 1_700_000_000))

    let documents = scanner.scanDocuments(in: [folder])
    let roadmap = documents.first(where: { $0.title == "Roadmap Snapshot" })
    let releaseNotes = documents.first(where: { $0.title == "Release Notes" })

    #expect(documents.count == 2)
    #expect(roadmap?.project == "Fixtures")
    #expect(roadmap?.path == "nested/roadmap.html")
    #expect(roadmap?.previewRootPath == fixturesURL.path)
    #expect(roadmap?.explainer?.contains("calm librarian") == true)
    #expect(releaseNotes?.explainer == nil)
    #expect(releaseNotes?.summary.contains("latest export run") == true)
}

@Test func previewResolverUsesPreviewRootWhenAvailable() async throws {
    let fixturesURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures", isDirectory: true)
    let document = DocumentItem(
        id: "fixture",
        title: "Roadmap Snapshot",
        project: "Fixtures",
        path: "nested/roadmap.html",
        absolutePath: fixturesURL.appendingPathComponent("nested/roadmap.html").path,
        previewRootPath: fixturesURL.path,
        summary: "Summary",
        explainer: nil,
        relativeTimestamp: "now"
    )
    let resolver = LocalHTMLPreviewResolver()

    let preview = resolver.resolve(document: document)

    #expect(preview == .available(
        LocalHTMLPreviewSource(
            fileURL: fixturesURL.appendingPathComponent("nested/roadmap.html"),
            readAccessURL: fixturesURL
        )
    ))
}

@Test func previewResolverReturnsUnavailableForSampleDocument() async throws {
    let resolver = LocalHTMLPreviewResolver()

    let preview = resolver.resolve(document: DocumentItem.sampleItems[0])

    #expect(preview == .unavailable(message: "This entry is currently sample content. A real HTML preview appears when the document comes from a watched folder."))
}

@Test func previewNavigationPolicyAllowsFilesInsidePreviewRoot() async throws {
    let source = LocalHTMLPreviewSource(
        fileURL: URL(fileURLWithPath: "/tmp/docs/nested/roadmap.html"),
        readAccessURL: URL(fileURLWithPath: "/tmp/docs", isDirectory: true)
    )
    let policy = LocalHTMLPreviewNavigationPolicy(source: source)

    let action = policy.action(
        for: URL(fileURLWithPath: "/tmp/docs/assets/site.css"),
        isMainFrame: true,
        navigationType: .other
    )

    #expect(action == .allow)
}

@Test func previewNavigationPolicyCancelsFilesOutsidePreviewRoot() async throws {
    let source = LocalHTMLPreviewSource(
        fileURL: URL(fileURLWithPath: "/tmp/docs/nested/roadmap.html"),
        readAccessURL: URL(fileURLWithPath: "/tmp/docs", isDirectory: true)
    )
    let policy = LocalHTMLPreviewNavigationPolicy(source: source)

    let action = policy.action(
        for: URL(fileURLWithPath: "/tmp/private/secrets.html"),
        isMainFrame: true,
        navigationType: .linkActivated
    )

    #expect(action == .cancel)
}

@Test func previewNavigationPolicyOpensExternalLinksInBrowser() async throws {
    let source = LocalHTMLPreviewSource(
        fileURL: URL(fileURLWithPath: "/tmp/docs/nested/roadmap.html"),
        readAccessURL: URL(fileURLWithPath: "/tmp/docs", isDirectory: true)
    )
    let policy = LocalHTMLPreviewNavigationPolicy(source: source)
    let url = try #require(URL(string: "https://example.com/docs"))

    let action = policy.action(
        for: url,
        isMainFrame: true,
        navigationType: .linkActivated
    )

    #expect(action == .openInBrowser(url))
}

@Test func previewFailurePresenterExplainsMissingFilesClearly() async throws {
    let presenter = LocalHTMLPreviewFailurePresenter()

    let message = presenter.message(
        for: NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorFileDoesNotExist
        )
    )

    #expect(message == "The HTML file disappeared before the preview could finish loading.")
}

@Test func launchOverridesReadFixtureFolderAndSelectedDocument() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    let htmlURL = tempRoot.appendingPathComponent("index.html")
    try Data("<html></html>".utf8).write(to: htmlURL)

    let overrides = LaunchOverrides(
        arguments: [
            "DevDashboardFeed",
            "--watched-folder", tempRoot.path,
            "--selected-document", htmlURL.path
        ],
        fileManager: fileManager
    )

    let watchedFolder = try #require(overrides.watchedFoldersOverride?.first)
    #expect(watchedFolder.path == tempRoot.path)
    #expect(watchedFolder.isAccessible == true)
    #expect(overrides.preferredDocumentSelectionID == htmlURL.path)
}

@MainActor
@Test func appModelLoadsScannerDocumentsWhenFoldersExist() async throws {
    let folder = WatchedFolder(
        id: UUID(),
        name: "docs",
        path: "/tmp/docs",
        bookmarkData: Data("bookmark".utf8),
        isAccessible: true
    )
    let scannedDocument = DocumentItem(
        id: "/tmp/docs/report.html",
        title: "Report",
        project: "docs",
        path: "report.html",
        absolutePath: "/tmp/docs/report.html",
        previewRootPath: "/tmp/docs",
        summary: "A scanned document.",
        explainer: nil,
        relativeTimestamp: "now"
    )
    let controller = FakeFolderAccessController(
        restoredFolders: [folder],
        chooseResult: .cancelled,
        removeResult: []
    )
    let scanner = FakeDocumentScanner(documents: [scannedDocument])
    let appModel = AppModel(folderAccessController: controller, documentScanner: scanner)

    #expect(appModel.documents == [scannedDocument])
}

@MainActor
@Test func appModelUsesLaunchOverrideFolderInsteadOfRestoredFolders() async throws {
    let fileManager = FileManager.default
    let tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try fileManager.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    let htmlURL = tempRoot.appendingPathComponent("daily/status.html")
    try fileManager.createDirectory(at: htmlURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("<html></html>".utf8).write(to: htmlURL)

    let restoredFolder = WatchedFolder(
        id: UUID(),
        name: "restored",
        path: "/tmp/restored",
        bookmarkData: Data("bookmark".utf8),
        isAccessible: true
    )
    let overrideDocument = DocumentItem(
        id: htmlURL.path,
        title: "Override",
        project: tempRoot.lastPathComponent,
        path: "daily/status.html",
        absolutePath: htmlURL.path,
        previewRootPath: tempRoot.path,
        summary: "Loaded from override.",
        explainer: nil,
        relativeTimestamp: "now"
    )
    let controller = FakeFolderAccessController(
        restoredFolders: [restoredFolder],
        chooseResult: .cancelled
    )
    let scanner = FakeDocumentScanner(documents: [overrideDocument])
    let appModel = AppModel(
        folderAccessController: controller,
        documentScanner: scanner,
        launchOverrides: LaunchOverrides(
            arguments: [
                "DevDashboardFeed",
                "--watched-folder", tempRoot.path,
                "--selected-document", htmlURL.path
            ],
            fileManager: fileManager
        )
    )

    #expect(appModel.watchedFolders.count == 1)
    #expect(appModel.watchedFolders[0].path == tempRoot.path)
    #expect(appModel.documents == [overrideDocument])
    #expect(appModel.preferredDocumentSelectionID == htmlURL.path)
}

@MainActor
@Test func appModelAddsChosenFolder() async throws {
    let chosenFolder = WatchedFolder(
        id: UUID(),
        name: "docs",
        path: "/tmp/docs",
        bookmarkData: Data("bookmark".utf8),
        isAccessible: true
    )
    let scannedDocument = DocumentItem(
        id: "/tmp/docs/guide.html",
        title: "Guide",
        project: "docs",
        path: "guide.html",
        absolutePath: "/tmp/docs/guide.html",
        previewRootPath: "/tmp/docs",
        summary: "A scanned guide.",
        explainer: "Helpful summary",
        relativeTimestamp: "now"
    )
    let controller = FakeFolderAccessController(
        restoredFolders: [],
        chooseResult: .added(folder: chosenFolder, updatedFolders: [chosenFolder])
    )
    let scanner = FakeDocumentScanner(documents: [scannedDocument])
    let appModel = AppModel(folderAccessController: controller, documentScanner: scanner)

    appModel.chooseWatchedFolder()

    #expect(appModel.watchedFolders == [chosenFolder])
    #expect(appModel.documents == [scannedDocument])
    #expect(appModel.folderStatusMessage == "\"docs\" was added.")
}

@MainActor
@Test func appModelRemovesFolder() async throws {
    let existingFolder = WatchedFolder(
        id: UUID(),
        name: "notes",
        path: "/tmp/notes",
        bookmarkData: Data("bookmark".utf8),
        isAccessible: true
    )
    let controller = FakeFolderAccessController(
        restoredFolders: [existingFolder],
        chooseResult: .cancelled,
        removeResult: []
    )
    let scanner = FakeDocumentScanner(documents: [])
    let appModel = AppModel(folderAccessController: controller, documentScanner: scanner)

    appModel.removeWatchedFolder(existingFolder)

    #expect(appModel.watchedFolders.isEmpty)
    #expect(appModel.documents == DocumentItem.sampleItems)
    #expect(appModel.folderStatusMessage == "\"notes\" was removed.")
}

@MainActor
private final class FakeFolderAccessController: FolderAccessControlling {
    let restoredFolders: [WatchedFolder]
    let chooseResult: FolderSelectionResult
    let removeResult: [WatchedFolder]

    init(
        restoredFolders: [WatchedFolder],
        chooseResult: FolderSelectionResult,
        removeResult: [WatchedFolder] = []
    ) {
        self.restoredFolders = restoredFolders
        self.chooseResult = chooseResult
        self.removeResult = removeResult
    }

    func restoreWatchedFolders() -> [WatchedFolder] {
        restoredFolders
    }

    func chooseFolder(existingFolders: [WatchedFolder]) throws -> FolderSelectionResult {
        chooseResult
    }

    func removeFolder(_ folder: WatchedFolder, from existingFolders: [WatchedFolder]) -> [WatchedFolder] {
        removeResult
    }
}

private struct FakeDocumentScanner: DocumentScanning {
    let documents: [DocumentItem]

    func scanDocuments(in folders: [WatchedFolder]) -> [DocumentItem] {
        documents
    }
}
