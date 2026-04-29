import Foundation

struct DocumentItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let project: String
    let path: String
    let absolutePath: String?
    let previewRootPath: String?
    let summary: String
    let explainer: String?
    let relativeTimestamp: String
}

extension DocumentItem {
    static let sampleItems: [DocumentItem] = [
        DocumentItem(
            id: "sample://hooks-overview",
            title: "Hooks Overview",
            project: "local-llm-lab",
            path: "docs/hooks-overview.html",
            absolutePath: nil,
            previewRootPath: nil,
            summary: "A compact overview of important hooks, what they do, and where they can go wrong in day-to-day work.",
            explainer: "Think of this as a calm reading layer over generated docs. The file still exists as normal, but the app makes it easy to revisit and understand.",
            relativeTimestamp: "5 min ago"
        ),
        DocumentItem(
            id: "sample://roadmap-snapshot",
            title: "Roadmap Snapshot",
            project: "portfolio",
            path: "docs/roadmap.html",
            absolutePath: nil,
            previewRootPath: nil,
            summary: "A visual roadmap update that highlights what changed since the last pass and what still needs decisions.",
            explainer: "Instead of opening HTML files one by one, the app should let you scroll through them like a feed and immediately see what is new.",
            relativeTimestamp: "Yesterday"
        ),
    ]
}
