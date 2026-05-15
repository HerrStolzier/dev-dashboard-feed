import SwiftUI

struct DocumentDetailView: View {
    let document: DocumentItem
    private let previewResolver = LocalHTMLPreviewResolver()
    @State private var previewLoadState: LocalHTMLPreviewLoadState = .idle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Mission Brief")
                    Text(document.summary)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(PixelpunkTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .pixelpunkPanel(accent: PixelpunkTheme.cyan)

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Erklaerbaer Power-Up")

                    if let explainer = document.explainer {
                        Text(explainer)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(PixelpunkTheme.ink)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PixelpunkTheme.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(PixelpunkTheme.amber.opacity(0.55), lineWidth: 1)
                            }
                    } else {
                        Text("No Erklaerbaer block was detected in this HTML file yet.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(PixelpunkTheme.muted)
                    }
                }
                .padding(18)
                .pixelpunkPanel(accent: PixelpunkTheme.amber)

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Artifact Preview")

                    previewSection
                }
                .padding(18)
                .pixelpunkPanel(accent: PixelpunkTheme.magenta)
            }
            .padding(28)
        }
        .background(PixelpunkTheme.appBackground)
        .navigationTitle(document.title)
        .onChange(of: document.id, initial: true) { _, _ in
            previewLoadState = .idle
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                PixelpunkBadge(text: document.sourceKind == .dailyDigest ? "Quest Complete" : "Source Artifact", accent: accentColor)
                PixelpunkBadge(text: document.relativeTimestamp, accent: PixelpunkTheme.green)
                PixelpunkBadge(text: "XP \(max(25, document.summary.count))", accent: PixelpunkTheme.amber)
            }

            Text(document.title)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(PixelpunkTheme.heroGradient)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label(document.project, systemImage: document.sourceKind == .dailyDigest ? "sparkles.rectangle.stack.fill" : "folder.fill")
                Label(document.path, systemImage: "shippingbox.fill")
            }
            .font(.system(.subheadline, design: .monospaced).weight(.bold))
            .foregroundStyle(PixelpunkTheme.muted)
        }
        .padding(22)
        .pixelpunkPanel(accent: accentColor, isRaised: true)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .monospaced).weight(.black))
            .foregroundStyle(PixelpunkTheme.ink)
    }

    @ViewBuilder
    private var previewSection: some View {
        switch previewResolver.resolve(document: document) {
        case .available(let source):
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    LocalHTMLPreviewView(
                        source: source,
                        loadState: $previewLoadState
                    )
                    .frame(minHeight: 420)

                    previewOverlay
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }

                Text("External links open outside the inline preview so this detail view stays focused on the current local file.")
                    .font(.footnote)
                    .foregroundStyle(PixelpunkTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .unavailable(let message):
            VStack(spacing: 12) {
                Image(systemName: "display.trianglebadge.exclamationmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(PixelpunkTheme.amber)

                Text("Preview Locked")
                    .font(.system(.title2, design: .monospaced).weight(.black))
                    .foregroundStyle(PixelpunkTheme.ink)

                Text(message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(PixelpunkTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(PixelpunkTheme.panelRaised, in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(PixelpunkTheme.border, lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var previewOverlay: some View {
        switch previewLoadState {
        case .idle, .ready:
            EmptyView()

        case .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Loading the local HTML preview...")
                    .font(.headline)
                Text("This also gives the document a chance to resolve nearby CSS, images, and other local assets.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PixelpunkTheme.panel.opacity(0.92))

        case .failed(let message):
            ContentUnavailableView(
                "Preview could not be loaded",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(PixelpunkTheme.panel.opacity(0.92))
        }
    }

    private var accentColor: Color {
        Color(devboardHex: document.accentColor ?? "#38bdf8")
    }
}
