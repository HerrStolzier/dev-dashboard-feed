import Foundation

protocol DocumentScanning {
    func scanDocuments(in folders: [WatchedFolder]) -> [DocumentItem]
}

struct DocumentScanner: DocumentScanning {
    private let fileManager: FileManager
    private let now: Date

    init(fileManager: FileManager = .default, now: Date = .now) {
        self.fileManager = fileManager
        self.now = now
    }

    func scanDocuments(in folders: [WatchedFolder]) -> [DocumentItem] {
        folders
            .filter(\.isAccessible)
            .flatMap(scanDocuments(in:))
            .sorted { $0.relativeSortKey > $1.relativeSortKey }
            .map(\.item)
    }

    private func scanDocuments(in folder: WatchedFolder) -> [ScannedDocument] {
        let rootURL = URL(fileURLWithPath: folder.path, isDirectory: true)

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var documents: [ScannedDocument] = []

        for case let fileURL as URL in enumerator {
            guard isHTMLFile(fileURL) else {
                continue
            }

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
                guard resourceValues.isRegularFile == true else {
                    continue
                }

                let document = try makeDocumentItem(
                    fileURL: fileURL,
                    rootURL: rootURL,
                    projectName: folder.name,
                    modificationDate: resourceValues.contentModificationDate
                )
                documents.append(document)
            } catch {
                continue
            }
        }

        return documents
    }

    private func makeDocumentItem(
        fileURL: URL,
        rootURL: URL,
        projectName: String,
        modificationDate: Date?
    ) throws -> ScannedDocument {
        let html = try loadHTML(from: fileURL)
        let title = extractTitle(from: html, fallback: fileURL.deletingPathExtension().lastPathComponent)
        let plainText = makePlainText(from: html)
        let summary = extractSummary(from: plainText)
        let explainer = extractExplainer(from: html)
        let relativePath = relativePath(for: fileURL, rootURL: rootURL)
        let modifiedAt = modificationDate ?? now

        return ScannedDocument(
            item: DocumentItem(
                id: fileURL.path,
                title: title,
                project: projectName,
                path: relativePath,
                absolutePath: fileURL.path,
                previewRootPath: rootURL.path,
                summary: summary,
                explainer: explainer,
                relativeTimestamp: relativeTimestamp(for: modifiedAt)
            ),
            relativeSortKey: modifiedAt
        )
    }

    private func isHTMLFile(_ fileURL: URL) -> Bool {
        ["html", "htm"].contains(fileURL.pathExtension.lowercased())
    }

    private func loadHTML(from fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)

        for encoding in [String.Encoding.utf8, .unicode, .isoLatin1, .windowsCP1252] {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    private func extractTitle(from html: String, fallback: String) -> String {
        if let title = firstMatch(
            in: html,
            pattern: #"(?is)<title[^>]*>\s*(.*?)\s*</title>"#
        ) {
            return cleanExtractedText(title, fallback: fallback)
        }

        if let title = firstMatch(
            in: html,
            pattern: #"(?is)<h1[^>]*>\s*(.*?)\s*</h1>"#
        ) {
            return cleanExtractedText(title, fallback: fallback)
        }

        return fallback
    }

    private func extractSummary(from plainText: String) -> String {
        let cleanedText = collapseWhitespace(in: plainText)

        guard !cleanedText.isEmpty else {
            return "No readable summary could be extracted from this HTML file yet."
        }

        if cleanedText.count <= 180 {
            return cleanedText
        }

        let summaryEnd = cleanedText.index(cleanedText.startIndex, offsetBy: 180)
        let shortened = cleanedText[..<summaryEnd]
        let trimmed = shortened.split(separator: " ").dropLast().joined(separator: " ")

        return trimmed.isEmpty ? String(shortened) + "…" : trimmed + "…"
    }

    private func extractExplainer(from html: String) -> String? {
        let blockPatterns = [
            #"(?is)<(?:section|div|aside|article|blockquote|p)[^>]*>\s*(?:<[^>]+>\s*)*Erklaerbaer\b.*?</(?:section|div|aside|article|blockquote|p)>"#,
            #"(?is)<h[1-6][^>]*>.*?Erklaerbaer.*?</h[1-6]>\s*<(?:p|div|section|blockquote)[^>]*>(.*?)</(?:p|div|section|blockquote)>"#
        ]

        for pattern in blockPatterns {
            if let rawMatch = firstMatch(in: html, pattern: pattern) {
                let cleaned = cleanExtractedText(rawMatch, fallback: "")
                if !cleaned.isEmpty {
                    return cleaned
                }
            }
        }

        let plainText = collapseWhitespace(in: makePlainText(from: html))
        guard let inlineExplainer = firstMatch(
            in: plainText,
            pattern: #"(?i)\bErklaerbaer\b\s*[:\-]\s*(.{1,180})"#
        ) else {
            return nil
        }
        let cleaned = collapseWhitespace(in: inlineExplainer)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func makePlainText(from html: String) -> String {
        let withoutScripts = replacingMatches(
            in: html,
            pattern: #"(?is)<script[^>]*>.*?</script>|<style[^>]*>.*?</style>"#,
            with: " "
        )
        let withoutTags = replacingMatches(
            in: withoutScripts,
            pattern: #"(?is)<[^>]+>"#,
            with: " "
        )
        let decodedEntities = withoutTags
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")

        return collapseWhitespace(in: decodedEntities)
    }

    private func relativePath(for fileURL: URL, rootURL: URL) -> String {
        let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
        let filePath = fileURL.path

        if filePath.hasPrefix(rootPath) {
            return String(filePath.dropFirst(rootPath.count))
        }

        return fileURL.lastPathComponent
    }

    private func relativeTimestamp(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }

    private func cleanExtractedText(_ text: String, fallback: String) -> String {
        let cleaned = collapseWhitespace(in: makePlainText(from: text))
        return cleaned.isEmpty ? fallback : cleaned
    }

    private func collapseWhitespace(in text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        let captureRange: NSRange
        if match.numberOfRanges > 1 {
            captureRange = match.range(at: 1)
        } else {
            captureRange = match.range(at: 0)
        }

        guard let swiftRange = Range(captureRange, in: text) else {
            return nil
        }

        return String(text[swiftRange])
    }

    private func replacingMatches(in text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}

private struct ScannedDocument {
    let item: DocumentItem
    let relativeSortKey: Date
}
