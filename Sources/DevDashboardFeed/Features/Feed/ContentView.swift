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
            .navigationTitle("Recent Docs")
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
        if appModel.watchedFolders.isEmpty {
            return "Choose your first folder to watch. The future app will scan local HTML files from there and show them in this feed."
        }

        if appModel.documents.isEmpty {
            return "The watched folders are connected, but no HTML files were found yet. Add some generated docs and they should appear here."
        }

        return "The app is already reading HTML metadata from \(appModel.watchedFolders.count) watched folder(s). The next step is a richer detail preview."
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
