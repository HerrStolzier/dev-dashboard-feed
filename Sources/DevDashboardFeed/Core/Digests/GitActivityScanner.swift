import Foundation

protocol GitActivityScanning: Sendable {
    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity
}

struct GitActivityScanner: GitActivityScanning {
    private let gitPath: String
    private let timeout: TimeInterval

    init(gitPath: String = "/usr/bin/git", timeout: TimeInterval = 45) {
        self.gitPath = gitPath
        self.timeout = timeout
    }

    func activity(for repo: ProjectRepo, since: Date?) throws -> GitRepoActivity {
        guard try isGitWorkTree(at: repo.path) else {
            throw GitActivityScannerError.notAGitRepository(repo.path)
        }

        var arguments = ["log", "--reverse", "--date=iso-strict", "--pretty=format:%H%x1f%h%x1f%an%x1f%aI%x1f%s"]
        if let since {
            arguments.insert("--since=\(ISO8601DateFormatter.devboardString(from: since))", at: 1)
        }

        let output = try runGit(arguments, in: repo.path)
        let entries = try output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
            .map(parseCommitLogEntry)
            .filter { commit in
                guard let since else {
                    return true
                }

                return commit.authoredAt > since
            }
        let commits = try entries.map { try makeCommitActivity(from: $0, repoPath: repo.path) }

        return GitRepoActivity(repo: repo, commits: commits)
    }

    private func isGitWorkTree(at path: String) throws -> Bool {
        let output = try runGit(["rev-parse", "--is-inside-work-tree"], in: path)
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }

    private func parseCommitLogEntry(_ line: String) throws -> GitCommitLogEntry {
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

        return GitCommitLogEntry(
            hash: hash,
            shortHash: parts[1],
            authorName: parts[2],
            authoredAt: authoredAt,
            subject: subject
        )
    }

    private func makeCommitActivity(from entry: GitCommitLogEntry, repoPath: String) throws -> GitCommitActivity {
        let changedFiles = try runGit(["show", "--pretty=format:", "--name-only", "--no-renames", entry.hash], in: repoPath)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        return GitCommitActivity(
            hash: entry.hash,
            shortHash: entry.shortHash,
            subject: entry.subject,
            authorName: entry.authorName,
            authoredAt: entry.authoredAt,
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
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if process.isRunning {
            process.terminate()
            Thread.sleep(forTimeInterval: 0.2)
            if process.isRunning {
                process.interrupt()
            }
            process.waitUntilExit()
            throw GitActivityScannerError.gitTimedOut(arguments.joined(separator: " "))
        }

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
    case gitTimedOut(String)
    case unparseableLogLine(String)
    case unparseableDate(String)

    var errorDescription: String? {
        switch self {
        case .notAGitRepository(let path):
            "This folder is not a Git repository: \(path)"
        case .gitFailed(let message):
            message.isEmpty ? "Git could not read activity for this repository." : message
        case .gitTimedOut(let command):
            "Git timed out while reading repository activity: git \(command)"
        case .unparseableLogLine:
            "Git returned a log line Devboard could not parse."
        case .unparseableDate(let value):
            "Git returned a date Devboard could not parse: \(value)"
        }
    }
}

private struct GitCommitLogEntry {
    let hash: String
    let shortHash: String
    let authorName: String
    let authoredAt: Date
    let subject: String
}

extension ISO8601DateFormatter {
    static func devboardDate(from string: String) -> Date? {
        formatter(options: [.withInternetDateTime]).date(from: string)
            ?? formatter(options: [.withInternetDateTime, .withFractionalSeconds]).date(from: string)
    }

    static func devboardString(from date: Date) -> String {
        formatter(options: [.withInternetDateTime]).string(from: date)
    }

    private static func formatter(options: Options) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = options
        return formatter
    }
}
