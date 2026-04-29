import AppKit
import Foundation
import Testing
import WebKit
@testable import DevDashboardFeed

@MainActor
@Test func previewFixtureIndexLoadsSharedAssetsInWebView() async throws {
    let fixtureRoot = previewFixtureRootURL()
    let webView = makePreviewTestWebView()
    let delegate = PreviewTestNavigationDelegate()
    webView.navigationDelegate = delegate

    async let didFinish = delegate.waitForNavigation()
    webView.loadFileURL(
        fixtureRoot.appendingPathComponent("index.html"),
        allowingReadAccessTo: fixtureRoot
    )
    try await didFinish
    try await Task.sleep(for: .milliseconds(150))

    let stylesheetLoaded = try await webView.boolValue(
        forJavaScript: #"Array.from(document.styleSheets).some(sheet => (sheet.href || "").endsWith("/assets/reader.css"))"#
    )
    let scriptProof = try await webView.stringValue(
        forJavaScript: #"document.getElementById("script-proof").textContent"#
    )
    let imageLoaded = try await webView.boolValue(
        forJavaScript: #"(() => { const image = document.querySelector(".hero-diagram"); return !!image && image.complete && image.naturalWidth > 0; })()"#
    )

    #expect(stylesheetLoaded)
    #expect(scriptProof.contains("Local JavaScript loaded from assets/proof.js"))
    #expect(imageLoaded)
}

@MainActor
@Test func previewFixtureNestedDocumentLoadsParentAssetsInWebView() async throws {
    let fixtureRoot = previewFixtureRootURL()
    let webView = makePreviewTestWebView()
    let delegate = PreviewTestNavigationDelegate()
    webView.navigationDelegate = delegate

    async let didFinish = delegate.waitForNavigation()
    webView.loadFileURL(
        fixtureRoot.appendingPathComponent("daily/status.html"),
        allowingReadAccessTo: fixtureRoot
    )
    try await didFinish
    try await Task.sleep(for: .milliseconds(150))

    let stylesheetLoaded = try await webView.boolValue(
        forJavaScript: #"Array.from(document.styleSheets).some(sheet => (sheet.href || "").endsWith("/assets/reader.css"))"#
    )
    let scriptProof = try await webView.stringValue(
        forJavaScript: #"document.getElementById("script-proof").textContent"#
    )
    let localLink = try await webView.stringValue(
        forJavaScript: #"document.querySelector('a[href="../notes/explainer.html"]').getAttribute("href")"#
    )

    #expect(stylesheetLoaded)
    #expect(scriptProof.contains("Local JavaScript loaded from assets/proof.js"))
    #expect(localLink == "../notes/explainer.html")
}

@MainActor
private func makePreviewTestWebView() -> WKWebView {
    _ = NSApplication.shared

    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    return WKWebView(frame: NSRect(x: 0, y: 0, width: 960, height: 720), configuration: configuration)
}

private func previewFixtureRootURL(filePath: String = #filePath) -> URL {
    URL(fileURLWithPath: filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/PreviewManual", isDirectory: true)
}

@MainActor
private final class PreviewTestNavigationDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    func waitForNavigation() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

@MainActor
private extension WKWebView {
    func boolValue(forJavaScript source: String) async throws -> Bool {
        let value = try await evaluateJavaScript(source)
        return value as? Bool == true
    }

    func stringValue(forJavaScript source: String) async throws -> String {
        let value = try await evaluateJavaScript(source)
        return value as? String ?? ""
    }
}
