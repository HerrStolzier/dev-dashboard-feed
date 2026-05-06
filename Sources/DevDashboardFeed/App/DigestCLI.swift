import Darwin
import Foundation

enum DigestCLI {
    static func runIfRequested(arguments: [String] = CommandLine.arguments) {
        let launchOverrides = LaunchOverrides(arguments: arguments)
        guard launchOverrides.shouldRunDigestsOnce
            || arguments.contains("--install-digest-agent")
            || arguments.contains("--uninstall-digest-agent")
            || arguments.contains("--kickstart-digest-agent") else {
            return
        }

        if arguments.contains("--install-digest-agent") {
            runAgentInstall(quiet: launchOverrides.quiet)
        }

        if arguments.contains("--uninstall-digest-agent") {
            runAgentUninstall(quiet: launchOverrides.quiet)
        }

        if arguments.contains("--kickstart-digest-agent") {
            runAgentKickstart(quiet: launchOverrides.quiet)
        }

        if let parseError = launchOverrides.parseError {
            fputs("Devboard Digest: \(parseError)\n", stderr)
            exit(2)
        }

        let result = DailyDigestCommand().run(now: launchOverrides.digestNow ?? .now)
        if !launchOverrides.quiet {
            print(summary(for: result.results))
        }

        exit(result.exitCode)
    }

    private static func runAgentInstall(quiet: Bool) -> Never {
        guard let executableURL = Bundle.main.executableURL else {
            fputs("Devboard Digest Agent: executable path is unavailable.\n", stderr)
            exit(2)
        }

        do {
            let plistURL = try DigestBackgroundService().install(executableURL: executableURL)
            if !quiet {
                print("Devboard Digest Agent installed: \(plistURL.path)")
            }
            exit(0)
        } catch {
            fputs("Devboard Digest Agent install failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func runAgentUninstall(quiet: Bool) -> Never {
        do {
            try DigestBackgroundService().uninstall()
            if !quiet {
                print("Devboard Digest Agent removed.")
            }
            exit(0)
        } catch {
            fputs("Devboard Digest Agent uninstall failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func runAgentKickstart(quiet: Bool) -> Never {
        do {
            try DigestBackgroundService().kickstart()
            if !quiet {
                print("Devboard Digest Agent started once.")
            }
            exit(0)
        } catch {
            fputs("Devboard Digest Agent kickstart failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func summary(for results: [DigestRunResult]) -> String {
        if results.isEmpty {
            return "Devboard Digest: no project repos are configured."
        }

        let lines = results.map { result in
            switch result {
            case .created(let repoName, let commitCount):
                "created \(repoName): \(commitCount) commit\(commitCount == 1 ? "" : "s")"
            case .skipped(let repoName):
                "skipped \(repoName): no new commits"
            case .failed(let repoName, let message):
                "failed \(repoName): \(message)"
            }
        }

        return "Devboard Digest:\n" + lines.joined(separator: "\n")
    }
}
