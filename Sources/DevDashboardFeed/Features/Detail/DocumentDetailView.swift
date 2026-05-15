import SwiftUI

struct DocumentDetailView: View {
    let document: DocumentItem
    private let previewResolver = LocalHTMLPreviewResolver()
    @State private var previewLoadState: LocalHTMLPreviewLoadState = .idle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                PixelpunkModule(title: "Mission Brief", icon: "scroll.fill", accent: accentColor, isCompact: true) {
                    Text(document.summary)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PixelpunkTheme.ink.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }

                PixelpunkModule(title: "Erklaerbaer Power-Up", icon: "star.square.fill", accent: PixelpunkTheme.amber, isCompact: true) {
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(PixelpunkTheme.amber.opacity(0.18))
                                .frame(width: 42, height: 42)
                            Image(systemName: "star.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(PixelpunkTheme.amber)
                        }

                        Text(document.explainer ?? "No Erklaerbaer block was detected in this HTML file yet.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(PixelpunkTheme.ink.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                PixelpunkModule(title: "Artifact Preview", accent: accentColor) {
                    previewSection
                }
            }
            .frame(maxWidth: PixelpunkTheme.detailMaxWidth, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(PixelpunkTheme.appBackground)
        .onChange(of: document.id, initial: true) { _, _ in
            previewLoadState = .idle
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    headerBadges
                }

                VStack(alignment: .leading, spacing: 8) {
                    headerBadges
                }
            }

            Text(document.title)
                .font(.system(size: 44, weight: .black, design: .monospaced))
                .foregroundStyle(PixelpunkTheme.heroGradient)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            VStack(alignment: .leading, spacing: 7) {
                Label(document.project, systemImage: document.sourceKind == .dailyDigest ? "sparkles.rectangle.stack.fill" : "folder.fill")
                    .lineLimit(1)
                    .truncationMode(.middle)

                Label(document.path, systemImage: "doc.badge.gearshape.fill")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(PixelpunkTheme.muted)
        }
        .padding(20)
        .pixelpunkPanel(accent: accentColor, isRaised: true)
    }

    private var headerBadges: some View {
        Group {
            PixelpunkBadge(text: document.sourceKind == .dailyDigest ? "Quest Log" : "Source", accent: accentColor)
            PixelpunkBadge(text: "Artifact", accent: PixelpunkTheme.cyan)
            PixelpunkBadge(text: document.relativeTimestamp, accent: PixelpunkTheme.green)
            PixelpunkBadge(text: "XP \(max(25, document.summary.count))", accent: PixelpunkTheme.amber)
        }
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
                .clipShape(RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
                        .stroke(PixelpunkTheme.border, lineWidth: 1)
                }

                Text("External links open outside the inline preview so this detail view stays focused on the current local file.")
                    .font(.footnote)
                    .foregroundStyle(PixelpunkTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .unavailable(let message):
            VStack(spacing: 12) {
                Image(systemName: "lock.rectangle.stack.fill")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(PixelpunkTheme.muted)

                Text("Preview Locked")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(PixelpunkTheme.ink)

                Text(message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(PixelpunkTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.vertical, 18)
            .background(PixelpunkTheme.panelRaised.opacity(0.58), in: RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
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
                Text("Loading local artifact...")
                    .font(.system(.headline, design: .monospaced))
                Text("Nearby CSS, images, and local assets get a chance to resolve.")
                    .font(.subheadline)
                    .foregroundStyle(PixelpunkTheme.muted)
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
        PixelpunkTheme.accent(for: document)
    }
}
