import Foundation

struct LaunchOverrides {
    private let watchedFolderPath: String?
    private let selectedDocumentPath: String?
    private let fileManager: FileManager

    init(
        arguments: [String] = CommandLine.arguments,
        fileManager: FileManager = .default
    ) {
        self.watchedFolderPath = LaunchOverrides.value(for: "--watched-folder", in: arguments)
        self.selectedDocumentPath = LaunchOverrides.value(for: "--selected-document", in: arguments)
        self.fileManager = fileManager
    }

    var watchedFoldersOverride: [WatchedFolder]? {
        guard let watchedFolderURL else {
            return nil
        }

        return [
            WatchedFolder(
                id: UUID(),
                name: watchedFolderURL.lastPathComponent,
                path: watchedFolderURL.path,
                bookmarkData: Data(),
                isAccessible: true
            )
        ]
    }

    var preferredDocumentSelectionID: DocumentItem.ID? {
        selectedDocumentURL?.path
    }

    private var watchedFolderURL: URL? {
        normalizedDirectoryURL(from: watchedFolderPath)
    }

    private var selectedDocumentURL: URL? {
        normalizedFileURL(from: selectedDocumentPath)
    }

    private func normalizedDirectoryURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        let url = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    private func normalizedFileURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    private static func value(for flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }

        let nextIndex = arguments.index(after: index)
        guard nextIndex < arguments.endIndex else {
            return nil
        }

        return arguments[nextIndex]
    }
}
