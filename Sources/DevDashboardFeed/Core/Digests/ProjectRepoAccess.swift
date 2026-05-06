import Foundation

struct ProjectRepoAccess {
    struct Restoration {
        let repos: [ProjectRepo]
        let activeURLs: [UUID: URL]

        func stopAccessing() {
            for url in activeURLs.values {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func restore(_ storedRepos: [ProjectRepo]) -> Restoration {
        var restoredRepos: [ProjectRepo] = []
        var activeURLs: [UUID: URL] = [:]

        for var repo in storedRepos {
            guard let bookmarkData = repo.bookmarkData else {
                restoredRepos.append(repo)
                continue
            }

            do {
                let (resolvedURL, isStale) = try resolveBookmark(bookmarkData)
                repo.name = resolvedURL.lastPathComponent
                repo.path = resolvedURL.standardizedFileURL.path
                repo.bookmarkData = isStale ? try makeBookmarkData(for: resolvedURL) : bookmarkData

                if fileManager.fileExists(atPath: repo.path),
                   resolvedURL.startAccessingSecurityScopedResource() {
                    activeURLs[repo.id] = resolvedURL
                }
            } catch {
                repo.isActive = false
            }

            restoredRepos.append(repo)
        }

        return Restoration(
            repos: restoredRepos.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            },
            activeURLs: activeURLs
        )
    }

    func makeBookmarkData(for url: URL) throws -> Data {
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
}
