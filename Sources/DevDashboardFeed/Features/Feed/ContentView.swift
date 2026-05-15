import SwiftUI

struct ContentView: View {
    let appModel: AppModel
    @State private var selection: DocumentItem.ID?

    var body: some View {
        NavigationSplitView {
            ZStack {
                PixelpunkTheme.background

                List(appModel.documents, selection: $selection) { document in
                    FeedCardView(document: document)
                        .tag(document.id)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Quest Feed")
            .toolbarBackground(PixelpunkTheme.background, for: .windowToolbar)
        } detail: {
            ZStack {
                PixelpunkTheme.appBackground
                    .ignoresSafeArea()

                if let selectedDocument = appModel.documents.first(where: { $0.id == selection }) {
                    DocumentDetailView(document: selectedDocument)
                } else {
                    VStack(spacing: 16) {
                        PixelpunkBadge(text: "No quest selected", accent: PixelpunkTheme.amber)

                        Text("Pick a Project Card")
                            .font(.system(size: 34, weight: .black, design: .rounded))
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
        }
        .frame(minWidth: 980, minHeight: 620)
        .toolbar {
            ToolbarItem {
                Button {
                    appModel.runDailyDigests()
                } label: {
                    Label(appModel.isDigestRunInProgress ? "Running" : "Run Digests", systemImage: "bolt.fill")
                }
                .disabled(appModel.projectRepos.filter(\.isActive).isEmpty || appModel.isDigestRunInProgress)
                .buttonStyle(PixelpunkButtonStyle(accent: PixelpunkTheme.green))
            }

            ToolbarItem {
                Button {
                    appModel.chooseWatchedFolder()
                } label: {
                    Label("Choose Folder", systemImage: "folder.badge.plus")
                }
                .buttonStyle(PixelpunkButtonStyle(accent: PixelpunkTheme.cyan))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            ensureValidSelection()
        }
        .onChange(of: appModel.documents) {
            ensureValidSelection()
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
