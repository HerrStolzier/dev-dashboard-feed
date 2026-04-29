import Foundation

struct DailyDigestRunOutput: Sendable {
    let updatedRepos: [ProjectRepo]
    let results: [DigestRunResult]
}

struct DailyDigestRunner: Sendable {
    let repos: [ProjectRepo]
    let scanner: any GitActivityScanning
    let renderer: DailyDigestRenderer
    let digestOutputRoot: URL

    func run(now: Date) -> DailyDigestRunOutput {
        var updatedRepos = repos
        var results: [DigestRunResult] = []

        for index in updatedRepos.indices {
            guard updatedRepos[index].isActive else {
                results.append(.skipped(repoName: updatedRepos[index].name))
                continue
            }

            let repo = updatedRepos[index]
            do {
                let crawlStart = repo.lastSuccessfulCrawlAt ?? Calendar.current.startOfDay(for: now)
                let activity = try scanner.activity(for: repo, since: crawlStart)

                guard !activity.commits.isEmpty else {
                    updatedRepos[index].lastSuccessfulCrawlAt = now
                    results.append(.skipped(repoName: repo.name))
                    continue
                }

                let html = renderer.render(activity: activity, generatedAt: now)
                let digestURL = digestFileURL(for: repo, date: now)
                try FileManager.default.createDirectory(at: digestURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(html.utf8).write(to: digestURL, options: .atomic)
                updatedRepos[index].lastSuccessfulCrawlAt = now
                results.append(.created(repoName: repo.name, commitCount: activity.commits.count))
            } catch {
                results.append(.failed(repoName: repo.name, message: error.localizedDescription))
            }
        }

        return DailyDigestRunOutput(updatedRepos: updatedRepos, results: results)
    }

    private func digestFileURL(for repo: ProjectRepo, date: Date) -> URL {
        digestOutputRoot
            .appendingPathComponent(DigestPath.directoryName(for: repo), isDirectory: true)
            .appendingPathComponent("\(DateFormatter.devboardFileDayString(from: date)).html")
    }
}

enum DigestPath {
    static func directoryName(for repo: ProjectRepo) -> String {
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
