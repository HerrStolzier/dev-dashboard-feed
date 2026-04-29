import Foundation

struct GitCommitActivity: Hashable, Sendable {
    let hash: String
    let shortHash: String
    let subject: String
    let authorName: String
    let authoredAt: Date
    let changedFiles: [String]
}

struct GitRepoActivity: Hashable, Sendable {
    let repo: ProjectRepo
    let commits: [GitCommitActivity]

    var changedFileCount: Int {
        Set(commits.flatMap(\.changedFiles)).count
    }
}

enum DigestRunResult: Hashable, Sendable {
    case created(repoName: String, commitCount: Int)
    case skipped(repoName: String)
    case failed(repoName: String, message: String)
}
