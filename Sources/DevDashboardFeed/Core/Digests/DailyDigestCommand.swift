import Foundation

struct DailyDigestCommandResult: Sendable {
    let output: DailyDigestRunOutput
    let storeSaveError: String?
    let metadataSaveError: String?

    var results: [DigestRunResult] {
        var results = output.results

        if let storeSaveError {
            results.append(.failed(repoName: "Project Repo Store", message: storeSaveError))
        }

        if let metadataSaveError {
            results.append(.failed(repoName: "Digest Metadata Store", message: metadataSaveError))
        }

        return results
    }

    var exitCode: Int32 {
        results.contains { result in
            if case .failed = result {
                return true
            }
            return false
        } ? 1 : 0
    }
}

struct DailyDigestCommand {
    let runtime: DigestRuntime
    let repoAccess: ProjectRepoAccess

    init(
        runtime: DigestRuntime = DigestRuntime(),
        repoAccess: ProjectRepoAccess = ProjectRepoAccess()
    ) {
        self.runtime = runtime
        self.repoAccess = repoAccess
    }

    func run(now: Date = .now) -> DailyDigestCommandResult {
        do {
            let storedRepos = try runtime.projectRepoStore.load()
            let restoration = repoAccess.restore(storedRepos)
            defer {
                restoration.stopAccessing()
            }

            let runner = DailyDigestRunner(
                repos: restoration.repos,
                scanner: runtime.scanner,
                renderer: runtime.renderer,
                digestOutputRoot: runtime.digestOutputRoot
            )
            let output = runner.run(now: now)

            do {
                try runtime.projectRepoStore.save(output.updatedRepos)
                let metadataSaveError = saveMetadata(for: output, now: now)
                return DailyDigestCommandResult(
                    output: output,
                    storeSaveError: nil,
                    metadataSaveError: metadataSaveError
                )
            } catch {
                let metadataSaveError = saveMetadata(for: output, now: now)
                return DailyDigestCommandResult(
                    output: output,
                    storeSaveError: error.localizedDescription,
                    metadataSaveError: metadataSaveError
                )
            }
        } catch {
            return DailyDigestCommandResult(
                output: DailyDigestRunOutput(updatedRepos: [], results: [
                    .failed(repoName: "Project Repo Store", message: error.localizedDescription),
                ]),
                storeSaveError: nil,
                metadataSaveError: nil
            )
        }
    }

    private func saveMetadata(for output: DailyDigestRunOutput, now: Date) -> String? {
        var metadata = (try? runtime.metadataStore.load()) ?? .empty
        let failures = output.results.compactMap { result -> String? in
            if case .failed(let repoName, let message) = result {
                return "\(repoName): \(message)"
            }
            return nil
        }

        metadata.lastRunAt = now
        metadata.lastErrorMessage = failures.isEmpty ? nil : failures.joined(separator: "\n")
        metadata.nextScheduledRunAt = DigestScheduler().nextScheduledRun(after: now)

        if failures.isEmpty {
            metadata.lastSuccessfulRunAt = now
        }

        do {
            try runtime.metadataStore.save(metadata)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
