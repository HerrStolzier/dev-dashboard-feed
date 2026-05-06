import Darwin
import Foundation

struct DigestLaunchAgentInstaller {
    static let defaultLabel = "com.herrstolzier.DevDashboardFeed.daily-digest"

    let label: String
    let fileManager: FileManager
    let launchAgentsDirectory: URL
    let logDirectory: URL

    init(
        label: String = DigestLaunchAgentInstaller.defaultLabel,
        fileManager: FileManager = .default,
        launchAgentsDirectory: URL? = nil,
        logDirectory: URL = DigestRuntime.defaultLogDirectory()
    ) {
        self.label = label
        self.fileManager = fileManager
        self.launchAgentsDirectory = launchAgentsDirectory
            ?? fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("LaunchAgents", isDirectory: true)
        self.logDirectory = logDirectory
    }

    var plistURL: URL {
        launchAgentsDirectory.appendingPathComponent("\(label).plist")
    }

    var isInstalled: Bool {
        fileManager.fileExists(atPath: plistURL.path)
    }

    func install(executableURL: URL) throws -> URL {
        try fileManager.createDirectory(at: launchAgentsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        let plist = DigestLaunchAgentPlist(
            label: label,
            executableURL: executableURL,
            standardOutURL: logDirectory.appendingPathComponent("daily-digest.out.log"),
            standardErrorURL: logDirectory.appendingPathComponent("daily-digest.err.log")
        )
        try plist.data().write(to: plistURL, options: .atomic)
        try bootstrap()
        return plistURL
    }

    func uninstall() throws {
        try? bootout()

        if fileManager.fileExists(atPath: plistURL.path) {
            try fileManager.removeItem(at: plistURL)
        }
    }

    func kickstart() throws {
        try runLaunchctl(["kickstart", "-k", "gui/\(userID())/\(label)"])
    }

    private func bootstrap() throws {
        try? bootout()
        try runLaunchctl(["bootstrap", "gui/\(userID())", plistURL.path])
    }

    private func bootout() throws {
        try runLaunchctl(["bootout", "gui/\(userID())/\(label)"])
    }

    private func userID() -> String {
        String(getuid())
    }

    private func runLaunchctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        ]

        let error = Pipe()
        process.standardError = error
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorText = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw DigestLaunchAgentInstallerError.launchctlFailed(errorText.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

enum DigestLaunchAgentInstallerError: LocalizedError, Equatable {
    case launchctlFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchctlFailed(let message):
            message.isEmpty ? "launchctl could not update the Daily Digest agent." : message
        }
    }
}
