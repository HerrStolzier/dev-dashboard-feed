import SwiftUI

struct ContentView: View {
    let appModel: AppModel
    @State private var selection: DocumentItem.ID?

    private var selectedDocument: DocumentItem? {
        appModel.documents.first(where: { $0.id == selection })
    }

    private var theme: PixelpunkProjectTheme {
        PixelpunkProjectTheme.theme(for: selectedDocument)
    }

    var body: some View {
        PixelpunkAppFrame(theme: theme) {
            VStack(spacing: 0) {
                chromeBar

                HStack(spacing: 0) {
                    sidebar

                    Rectangle()
                        .fill(PixelpunkTheme.border)
                        .frame(width: 1)

                    detailShell
                }
            }
        }
        .frame(minWidth: 1120, minHeight: 700)
        .preferredColorScheme(.dark)
        .onAppear {
            ensureValidSelection()
        }
        .onChange(of: appModel.documents) {
            ensureValidSelection()
        }
    }

    private var chromeBar: some View {
        HStack(spacing: 14) {
            PixelpunkBadge(text: "Local Feed", accent: theme.accent)

            Text(statusText)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(PixelpunkTheme.muted)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    appModel.runDailyDigests()
                } label: {
                    Image(systemName: "bolt.fill")
                        .frame(width: 18, height: 18)
                }
                .disabled(appModel.projectRepos.filter(\.isActive).isEmpty || appModel.isDigestRunInProgress)
                .buttonStyle(PixelpunkButtonStyle(accent: theme.accent))

                Button {
                    appModel.chooseWatchedFolder()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(PixelpunkButtonStyle(accent: PixelpunkTheme.cyan))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color.black.opacity(0.28))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PixelpunkTheme.border)
                .frame(height: 1)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEVBOARD")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(theme.accent)

                Text("QUEST FEED")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(PixelpunkTheme.ink)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(appModel.documents) { document in
                        Button {
                            selection = document.id
                        } label: {
                            FeedCardView(
                                document: document,
                                isSelected: selection == document.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 314)
        .background(
            ZStack {
                PixelpunkTheme.background.opacity(0.94)

                LinearGradient(
                    colors: [theme.glow.opacity(0.12), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    private var detailShell: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: selectedDocument?.sourceKind == .dailyDigest ? "sparkles.rectangle.stack.fill" : "rectangle.stack.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(PixelpunkTheme.ink)

                Text(selectedDocument?.title ?? "No Quest Selected")
                    .font(.system(size: 19, weight: .black, design: .monospaced))
                    .foregroundStyle(PixelpunkTheme.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(Color.black.opacity(0.20))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(PixelpunkTheme.border)
                    .frame(height: 1)
            }

            if let selectedDocument {
                DocumentDetailView(document: selectedDocument)
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            PixelpunkTheme.appBackground

            VStack(spacing: 14) {
                PixelpunkBadge(text: "No quest selected", accent: PixelpunkTheme.amber)

                Text("Pick a Project Card")
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundStyle(PixelpunkTheme.ink)

                Text(detailDescription)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(PixelpunkTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }
            .padding(28)
            .pixelpunkPanel(accent: PixelpunkTheme.amber, isRaised: true)
            .padding(40)
        }
    }

    private var detailDescription: String {
        if appModel.watchedFolders.isEmpty && appModel.projectRepos.isEmpty {
            return "Choose a project repo for Daily Digests or a folder of local HTML files. The feed will turn those local artifacts into a timeline."
        }

        if appModel.documents.isEmpty {
            return "The sources are connected, but nothing is ready for the feed yet. Run Daily Digests or add generated HTML files."
        }

        return "The app is reading \(appModel.documents.count) local feed item(s), including manual HTML files and generated project digests."
    }

    private var statusText: String {
        let repoCount = appModel.projectRepos.count
        let itemCount = appModel.documents.count
        return "\(itemCount) item\(itemCount == 1 ? "" : "s") · \(repoCount) repo\(repoCount == 1 ? "" : "s")"
    }

    private func ensureValidSelection() {
        if let selection, appModel.documents.contains(where: { $0.id == selection }) {
            return
        }

        if let preferredSelectionID = appModel.preferredDocumentSelectionID,
           appModel.documents.contains(where: { $0.id == preferredSelectionID }) {
            self.selection = preferredSelectionID
            return
        }

        self.selection = appModel.documents.first?.id
    }
}
