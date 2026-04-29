import AppKit
import SwiftUI
import WebKit

struct LocalHTMLPreviewView: NSViewRepresentable {
    let source: LocalHTMLPreviewSource
    @Binding var loadState: LocalHTMLPreviewLoadState

    func makeCoordinator() -> Coordinator {
        Coordinator(loadState: $loadState, source: source)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.update(loadState: $loadState, source: source)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        context.coordinator.loadPreview(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(loadState: $loadState, source: source)
        let currentURL = webView.url?.standardizedFileURL
        let targetURL = source.fileURL.standardizedFileURL

        if context.coordinator.lastLoadedSource != source || currentURL != targetURL {
            context.coordinator.loadPreview(in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private var loadState: Binding<LocalHTMLPreviewLoadState>
        private var source: LocalHTMLPreviewSource
        private let failurePresenter = LocalHTMLPreviewFailurePresenter()

        private(set) var lastLoadedSource: LocalHTMLPreviewSource?

        init(
            loadState: Binding<LocalHTMLPreviewLoadState>,
            source: LocalHTMLPreviewSource
        ) {
            self.loadState = loadState
            self.source = source
        }

        func update(
            loadState: Binding<LocalHTMLPreviewLoadState>,
            source: LocalHTMLPreviewSource
        ) {
            self.loadState = loadState
            self.source = source
        }

        func loadPreview(in webView: WKWebView) {
            lastLoadedSource = source
            setLoadState(.loading)
            webView.loadFileURL(
                source.fileURL.standardizedFileURL,
                allowingReadAccessTo: source.readAccessURL.standardizedFileURL
            )
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            setLoadState(.loading)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            setLoadState(.ready)
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: any Error
        ) {
            setLoadState(.failed(message: failurePresenter.message(for: error)))
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: any Error
        ) {
            setLoadState(.failed(message: failurePresenter.message(for: error)))
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            let message = failurePresenter.message(
                for: NSError(
                    domain: WKError.errorDomain,
                    code: WKError.webContentProcessTerminated.rawValue
                )
            )
            setLoadState(.failed(message: message))
        }

        @MainActor
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            let action = LocalHTMLPreviewNavigationPolicy(source: source).action(
                for: navigationAction.request.url,
                isMainFrame: isMainFrame,
                navigationType: navigationAction.navigationType
            )

            switch action {
            case .allow:
                decisionHandler(.allow)
            case .cancel:
                decisionHandler(.cancel)
            case .openInBrowser(let url):
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        private func setLoadState(_ newValue: LocalHTMLPreviewLoadState) {
            guard loadState.wrappedValue != newValue else {
                return
            }

            loadState.wrappedValue = newValue
        }
    }
}
