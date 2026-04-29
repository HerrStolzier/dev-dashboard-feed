import Foundation

struct WatchedFolder: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: String
    let bookmarkData: Data
    let isAccessible: Bool
}

extension WatchedFolder {
    var statusText: String {
        isAccessible ? "Ready" : "Needs access again"
    }
}
