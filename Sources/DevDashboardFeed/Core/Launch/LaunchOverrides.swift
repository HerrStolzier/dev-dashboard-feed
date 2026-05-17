import Foundation

struct LaunchOverrides {
    private let watchedFolderPath: String?
    private let selectedDocumentPath: String?
    private let digestNowValue: String?
    private let projectRepoStorePath: String?
    private let digestOutputRootPath: String?
    private let digestMetadataStorePath: String?
    private let digestHistoryStorePath: String?
    private let digestLockPath: String?
    private let fileManager: FileManager
    let shouldRunDigestsOnce: Bool
    let quiet: Bool
    let parseError: String?

    init(
        arguments: [String] = CommandLine.arguments,
        fileManager: FileManager = .default
    ) {
        self.watchedFolderPath = LaunchOverrides.value(for: "--watched-folder", in: arguments)
        self.selectedDocumentPath = LaunchOverrides.value(for: "--selected-document", in: arguments)
        self.digestNowValue = LaunchOverrides.value(for: "--digest-now", in: arguments)
        self.projectRepoStorePath = LaunchOverrides.value(for: "--project-repo-store", in: arguments)
        self.digestOutputRootPath = LaunchOverrides.value(for: "--digest-output-root", in: arguments)
        self.digestMetadataStorePath = LaunchOverrides.value(for: "--digest-metadata-store", in: arguments)
        self.digestHistoryStorePath = LaunchOverrides.value(for: "--digest-history-store", in: arguments)
        self.digestLockPath = LaunchOverrides.value(for: "--digest-lock", in: arguments)
        self.shouldRunDigestsOnce = arguments.contains("--run-digests-once")
        self.quiet = arguments.contains("--quiet")
        self.fileManager = fileManager

        if arguments.contains("--digest-now"), digestNowValue == nil {
            self.parseError = "--digest-now needs an ISO-8601 date value."
        } else if let digestNowValue,
                  ISO8601DateFormatter.devboardDate(from: digestNowValue) == nil {
            self.parseError = "--digest-now could not parse date: \(digestNowValue)"
        } else {
            self.parseError = nil
        }
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

    var digestNow: Date? {
        guard let digestNowValue else {
            return nil
        }

        return ISO8601DateFormatter.devboardDate(from: digestNowValue)
    }

    var projectRepoStoreURL: URL? {
        normalizedWritableFileURL(from: projectRepoStorePath)
    }

    var digestOutputRootURL: URL? {
        normalizedWritableDirectoryURL(from: digestOutputRootPath)
    }

    var digestMetadataStoreURL: URL? {
        normalizedWritableFileURL(from: digestMetadataStorePath)
    }

    var digestHistoryStoreURL: URL? {
        normalizedWritableFileURL(from: digestHistoryStorePath)
    }

    var digestLockURL: URL? {
        normalizedWritableFileURL(from: digestLockPath)
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

    private func normalizedWritableFileURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: path).standardizedFileURL
    }

    private func normalizedWritableDirectoryURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
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
