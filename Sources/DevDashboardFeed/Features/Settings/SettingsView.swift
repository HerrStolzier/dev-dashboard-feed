import SwiftUI

struct SettingsView: View {
    let appModel: AppModel

    var body: some View {
        Form {
            Section("Watched folders") {
                if watchedFolders.isEmpty {
                    Text("No folders configured yet.")
                    Text("Choose a folder once and the app will try to reopen it automatically after restart.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(watchedFolders.enumerated()), id: \.element.id) { _, folder in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.name)
                                        .font(.headline)

                                    Text(folder.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }

                                Spacer()

                                Button("Remove", role: .destructive) {
                                    appModel.removeWatchedFolder(folder)
                                }
                            }

                            Label(folder.statusText, systemImage: folder.isAccessible ? "checkmark.circle" : "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(folder.isAccessible ? Color.secondary : Color.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button("Choose Folder…") {
                    appModel.chooseWatchedFolder()
                }
            }

            if let folderStatusMessage = appModel.folderStatusMessage {
                Section("Latest status") {
                    Text(folderStatusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Product stance") {
                Text("Local-first")
                Text("HTML files stay untouched")
                Text("Feed before file browser")
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var watchedFolders: [WatchedFolder] {
        appModel.watchedFolders
    }
}
