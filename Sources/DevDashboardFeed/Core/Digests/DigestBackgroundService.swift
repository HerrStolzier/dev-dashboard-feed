import Foundation

protocol DigestBackgroundServicing {
    var status: DigestBackgroundServiceStatus { get }
    var plistURL: URL { get }

    func install(executableURL: URL) throws -> URL
    func uninstall() throws
    func kickstart() throws
}

enum DigestBackgroundServiceStatus: Hashable, Sendable {
    case installed
    case notInstalled
}

struct DigestBackgroundService: DigestBackgroundServicing {
    private let installer: DigestLaunchAgentInstaller

    init(installer: DigestLaunchAgentInstaller = DigestLaunchAgentInstaller()) {
        self.installer = installer
    }

    var status: DigestBackgroundServiceStatus {
        installer.isInstalled ? .installed : .notInstalled
    }

    var plistURL: URL {
        installer.plistURL
    }

    func install(executableURL: URL) throws -> URL {
        try installer.install(executableURL: executableURL)
    }

    func uninstall() throws {
        try installer.uninstall()
    }

    func kickstart() throws {
        try installer.kickstart()
    }
}
