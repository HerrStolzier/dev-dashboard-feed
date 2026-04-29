import Foundation
import WebKit

struct LocalHTMLPreviewSource: Equatable {
    let fileURL: URL
    let readAccessURL: URL
}

enum LocalHTMLPreviewAvailability: Equatable {
    case available(LocalHTMLPreviewSource)
    case unavailable(message: String)
}

enum LocalHTMLPreviewLoadState: Equatable {
    case idle
    case loading
    case ready
    case failed(message: String)
}

enum LocalHTMLPreviewNavigationAction: Equatable {
    case allow
    case cancel
    case openInBrowser(URL)
}

struct LocalHTMLPreviewNavigationPolicy {
    let source: LocalHTMLPreviewSource

    func action(
        for requestURL: URL?,
        isMainFrame: Bool,
        navigationType: WKNavigationType
    ) -> LocalHTMLPreviewNavigationAction {
        guard let requestURL else {
            return .allow
        }

        guard isMainFrame else {
            return .allow
        }

        if requestURL.isFileURL {
            return requestURL.isWithin(directory: source.readAccessURL) ? .allow : .cancel
        }

        return navigationType == .linkActivated ? .openInBrowser(requestURL) : .cancel
    }
}

struct LocalHTMLPreviewFailurePresenter {
    func message(for error: any Error) -> String {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorFileDoesNotExist {
            return "The HTML file disappeared before the preview could finish loading."
        }

        if nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorNoPermissionsToReadFile {
            return "The app no longer has permission to read this local HTML file."
        }

        if nsError.domain == WKError.errorDomain,
           nsError.code == WKError.webContentProcessTerminated.rawValue {
            return "The preview process stopped unexpectedly. Try opening the document again."
        }

        if !nsError.localizedDescription.isEmpty {
            return "The local HTML preview could not finish loading. \(nsError.localizedDescription)"
        }

        return "The local HTML preview could not finish loading."
    }
}

struct LocalHTMLPreviewResolver {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func resolve(document: DocumentItem) -> LocalHTMLPreviewAvailability {
        guard let absolutePath = document.absolutePath else {
            return .unavailable(message: "This entry is currently sample content. A real HTML preview appears when the document comes from a watched folder.")
        }

        let fileURL = URL(fileURLWithPath: absolutePath)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .unavailable(message: "The HTML file could not be found at its last known path.")
        }

        let readAccessURL: URL
        if let previewRootPath = document.previewRootPath,
           fileManager.fileExists(atPath: previewRootPath) {
            readAccessURL = URL(fileURLWithPath: previewRootPath, isDirectory: true)
        } else {
            readAccessURL = fileURL.deletingLastPathComponent()
        }

        return .available(
            LocalHTMLPreviewSource(
                fileURL: fileURL,
                readAccessURL: readAccessURL
            )
        )
    }
}

private extension URL {
    func isWithin(directory directoryURL: URL) -> Bool {
        let filePath = standardizedFileURL.resolvingSymlinksInPath().path
        let directoryPath = directoryURL.standardizedFileURL.resolvingSymlinksInPath().path
        let normalizedDirectory = directoryPath.hasSuffix("/") ? String(directoryPath.dropLast()) : directoryPath

        return filePath == normalizedDirectory || filePath.hasPrefix(normalizedDirectory + "/")
    }
}
