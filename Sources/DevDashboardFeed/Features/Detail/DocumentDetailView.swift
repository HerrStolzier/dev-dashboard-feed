import SwiftUI

struct DocumentDetailView: View {
    let document: DocumentItem
    private let previewResolver = LocalHTMLPreviewResolver()
    @State private var previewLoadState: LocalHTMLPreviewLoadState = .idle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(document.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        Label(document.project, systemImage: "folder")
                        Label(document.path, systemImage: "doc")
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Summary")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(document.summary)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Erklaerbaer Highlight")
                        .font(.title3)
                        .fontWeight(.semibold)

                    if let explainer = document.explainer {
                        Text(explainer)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    } else {
                        Text("No Erklaerbaer block was detected in this HTML file yet.")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("HTML Preview")
                        .font(.title3)
                        .fontWeight(.semibold)

                    previewSection
                }
            }
            .padding(28)
        }
        .navigationTitle(document.title)
        .onChange(of: document.id, initial: true) { _, _ in
            previewLoadState = .idle
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }

                Text("External links open outside the inline preview so this detail view stays focused on the current local file.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .unavailable(let message):
            ContentUnavailableView(
                "Preview not available",
                systemImage: "doc.richtext",
                description: Text(message)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            .background(.regularMaterial)

        case .failed(let message):
            ContentUnavailableView(
                "Preview could not be loaded",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(.regularMaterial)
        }
    }
}
