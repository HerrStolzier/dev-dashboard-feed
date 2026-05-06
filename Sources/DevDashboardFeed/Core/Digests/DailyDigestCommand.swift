import Foundation

struct DailyDigestCommandResult: Sendable {
    let output: DailyDigestRunOutput
    let storeSaveError: String?

    var results: [DigestRunResult] {
        if let storeSaveError {
            output.results + [.failed(repoName: "Project Repo Store", message: storeSaveError)]
        } else {
            output.results
        }
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
                return DailyDigestCommandResult(output: output, storeSaveError: nil)
            } catch {
                return DailyDigestCommandResult(output: output, storeSaveError: error.localizedDescription)
            }
        } catch {
            return DailyDigestCommandResult(
                output: DailyDigestRunOutput(updatedRepos: [], results: [
                    .failed(repoName: "Project Repo Store", message: error.localizedDescription),
                ]),
                storeSaveError: nil
            )
        }
    }
}
