import AppKit
import Foundation

@MainActor
protocol FolderAccessControlling {
    func restoreWatchedFolders() -> [WatchedFolder]
    func chooseFolder(existingFolders: [WatchedFolder]) throws -> FolderSelectionResult
    func removeFolder(_ folder: WatchedFolder, from existingFolders: [WatchedFolder]) -> [WatchedFolder]
}

enum FolderSelectionResult {
    case added(folder: WatchedFolder, updatedFolders: [WatchedFolder])
    case alreadyAdded(WatchedFolder)
    case cancelled
}

@MainActor
final class FolderAccessManager: FolderAccessControlling {
    static let shared = FolderAccessManager()

    private let storageKey = "watchedFolders.v1"
    private let userDefaults = UserDefaults.standard
    private var activeURLs: [UUID: URL] = [:]

    func restoreWatchedFolders() -> [WatchedFolder] {
        let storedFolders = loadStoredFolders()
        var restoredFolders: [WatchedFolder] = []

        for storedFolder in storedFolders {
            do {
                let (resolvedURL, isStale) = try resolveBookmark(storedFolder.bookmarkData)
                let refreshedBookmark = isStale ? try makeBookmarkData(for: resolvedURL) : storedFolder.bookmarkData
                let startedSecurityScope = resolvedURL.startAccessingSecurityScopedResource()

                if startedSecurityScope {
                    activeURLs[storedFolder.id] = resolvedURL
                }

                restoredFolders.append(
                    WatchedFolder(
                        id: storedFolder.id,
                        name: resolvedURL.lastPathComponent,
                        path: resolvedURL.path,
                        bookmarkData: refreshedBookmark,
                        isAccessible: true
                    )
                )
            } catch {
                restoredFolders.append(
                    WatchedFolder(
                        id: storedFolder.id,
                        name: storedFolder.name,
                        path: storedFolder.path,
                        bookmarkData: storedFolder.bookmarkData,
                        isAccessible: false
                    )
                )
            }
        }

        let sortedFolders = sortFolders(restoredFolders)
        persist(sortedFolders)
        return sortedFolders
    }

    func chooseFolder(existingFolders: [WatchedFolder]) throws -> FolderSelectionResult {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to watch"
        panel.message = "The app stores a bookmark so it can reopen this folder after restart."
        panel.prompt = "Choose Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.resolvesAliases = true

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return .cancelled
        }

        let normalizedPath = selectedURL.standardizedFileURL.path
        if let existingFolder = existingFolders.first(where: { $0.path == normalizedPath }) {
            return .alreadyAdded(existingFolder)
        }

        let bookmarkData = try makeBookmarkData(for: selectedURL)
        let startedSecurityScope = selectedURL.startAccessingSecurityScopedResource()
        let folder = WatchedFolder(
            id: UUID(),
            name: selectedURL.lastPathComponent,
            path: normalizedPath,
            bookmarkData: bookmarkData,
            isAccessible: true
        )

        if startedSecurityScope {
            activeURLs[folder.id] = selectedURL
        }

        let updatedFolders = sortFolders(existingFolders + [folder])
        persist(updatedFolders)
        return .added(folder: folder, updatedFolders: updatedFolders)
    }

    func removeFolder(_ folder: WatchedFolder, from existingFolders: [WatchedFolder]) -> [WatchedFolder] {
        if let activeURL = activeURLs.removeValue(forKey: folder.id) {
            activeURL.stopAccessingSecurityScopedResource()
        }

        let updatedFolders = existingFolders.filter { $0.id != folder.id }
        persist(updatedFolders)
        return updatedFolders
    }

    private func sortFolders(_ folders: [WatchedFolder]) -> [WatchedFolder] {
        folders.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func makeBookmarkData(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            return try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        }
    }

    private func resolveBookmark(_ bookmarkData: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false

        do {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (resolvedURL.standardizedFileURL, isStale)
        } catch {
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return (resolvedURL.standardizedFileURL, isStale)
        }
    }

    private func loadStoredFolders() -> [StoredWatchedFolder] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoredWatchedFolder].self, from: data)
        } catch {
            return []
        }
    }

    private func persist(_ folders: [WatchedFolder]) {
        let storedFolders = folders.map {
            StoredWatchedFolder(
                id: $0.id,
                name: $0.name,
                path: $0.path,
                bookmarkData: $0.bookmarkData
            )
        }

        do {
            let data = try JSONEncoder().encode(storedFolders)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            userDefaults.removeObject(forKey: storageKey)
        }
    }
}

private struct StoredWatchedFolder: Codable {
    let id: UUID
    let name: String
    let path: String
    let bookmarkData: Data
}
