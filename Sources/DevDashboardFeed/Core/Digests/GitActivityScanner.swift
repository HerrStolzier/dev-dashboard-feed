import Foundation

protocol GitActivityScanning {
    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity
}

struct GitActivityScanner: GitActivityScanning {
    private let gitPath: String

    init(gitPath: String = "/usr/bin/git") {
        self.gitPath = gitPath
    }

    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity {
        guard try isGitWorkTree(at: repo.path) else {
            throw GitActivityScannerError.notAGitRepository(repo.path)
        }

        let output = try runGit(["log", "--reverse", "--date=iso-strict", "--pretty=format:%H%x1f%h%x1f%an%x1f%aI%x1f%s"], in: repo.path)
        let commits = try output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
            .map { try parseCommitLine($0, repoPath: repo.path) }
            .filter { commit in
                guard let since else {
                    return true
                }

                return commit.authoredAt > since
            }

        return GitRepoActivity(repo: repo, commits: commits)
    }

    private func isGitWorkTree(at path: String) throws -> Bool {
        let output = try runGit(["rev-parse", "--is-inside-work-tree"], in: path)
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    private func parseCommitLine(_ line: String, repoPath: String) throws -> GitCommitActivity {
        let parts = line.components(separatedBy: "\u{1f}")
        guard parts.count >= 5 else {
            throw GitActivityScannerError.unparseableLogLine(line)
        }

        let hash = parts[0]
        let dateString = parts[3]
        let subject = parts.dropFirst(4).joined(separator: "\u{1f}")
        guard let authoredAt = ISO8601DateFormatter.devboardDate(from: dateString) else {
            throw GitActivityScannerError.unparseableDate(dateString)
        }

        let changedFiles = try runGit(["show", "--pretty=format:", "--name-only", "--no-renames", hash], in: repoPath)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        return GitCommitActivity(
            hash: hash,
            shortHash: parts[1],
            subject: subject,
            authorName: parts[2],
            authoredAt: authoredAt,
            changedFiles: changedFiles
        )
    }

    private func runGit(_ arguments: [String], in path: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = ["-C", path] + arguments

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        try process.run()
        process.waitUntilExit()

        let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            let errorText = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw GitActivityScannerError.gitFailed(errorText.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outputText
    }
}

enum GitActivityScannerError: LocalizedError, Equatable {
    case notAGitRepository(String)
    case gitFailed(String)
    case unparseableLogLine(String)
    case unparseableDate(String)

    var errorDescription: String? {
        switch self {
        case .notAGitRepository(let path):
            "This folder is not a Git repository: \(path)"
        case .gitFailed(let message):
            message.isEmpty ? "Git could not read activity for this repository." : message
        case .unparseableLogLine:
            "Git returned a log line Devboard could not parse."
        case .unparseableDate(let value):
            "Git returned a date Devboard could not parse: \(value)"
        }
    }
}

extension ISO8601DateFormatter {
    static func devboardDate(from string: String) -> Date? {
        formatter(options: [.withInternetDateTime]).date(from: string)
            ?? formatter(options: [.withInternetDateTime, .withFractionalSeconds]).date(from: string)
    }

    private static func formatter(options: Options) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = options
        return formatter
    }
}
