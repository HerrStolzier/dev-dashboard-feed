import Foundation

struct DigestRunMetadata: Codable, Equatable, Sendable {
    var lastRunAt: Date?
    var lastSuccessfulRunAt: Date?
    var lastErrorMessage: String?
    var nextScheduledRunAt: Date?

    static let empty = DigestRunMetadata(
        lastRunAt: nil,
        lastSuccessfulRunAt: nil,
        lastErrorMessage: nil,
        nextScheduledRunAt: nil
    )
}
