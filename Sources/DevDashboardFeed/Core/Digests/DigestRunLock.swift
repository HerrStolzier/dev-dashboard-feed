import Darwin
import Foundation

struct DigestRunLock: Sendable {
    let lockURL: URL

    init(
        lockURL: URL = DigestRunLock.defaultLockURL(),
        fileManager: FileManager = .default
    ) {
        self.lockURL = lockURL
    }

    func withLock<T>(_ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: lockURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            throw DigestRunLockError.couldNotOpenLock
        }
        defer {
            close(descriptor)
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            throw DigestRunLockError.alreadyRunning
        }
        defer {
            flock(descriptor, LOCK_UN)
        }

        return try body()
    }

    static func defaultLockURL(fileManager: FileManager = .default) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("DevDashboardFeed", isDirectory: true)
            .appendingPathComponent("daily-digest.lock")
    }
}

enum DigestRunLockError: LocalizedError, Equatable {
    case alreadyRunning
    case couldNotOpenLock

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            "Daily Digests are already running in another Devboard process."
        case .couldNotOpenLock:
            "Devboard could not open the Daily Digest lock file."
        }
    }
}
