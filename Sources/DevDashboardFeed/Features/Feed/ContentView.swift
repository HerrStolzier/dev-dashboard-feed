import SwiftUI

struct ContentView: View {
    let appModel: AppModel
    @State private var selection: DocumentItem.ID?

    var body: some View {
        NavigationSplitView {
            List(appModel.documents, selection: $selection) { document in
                FeedCardView(document: document)
                    .tag(document.id)
            }
            .navigationTitle("Project Feed")
        } detail: {
            if let selectedDocument = appModel.documents.first(where: { $0.id == selection }) {
                DocumentDetailView(document: selectedDocument)
            } else {
                ContentUnavailableView(
                    "Select a document",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(detailDescription)
                )
            }
        }
        .frame(minWidth: 980, minHeight: 620)
        .toolbar {
            ToolbarItem {
                Button("Run Digests") {
                    appModel.runDailyDigests()
                }
                .disabled(appModel.projectRepos.filter(\.isActive).isEmpty)
            }

            ToolbarItem {
                Button("Choose Folder…") {
                    appModel.chooseWatchedFolder()
                }
            }
        }
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
