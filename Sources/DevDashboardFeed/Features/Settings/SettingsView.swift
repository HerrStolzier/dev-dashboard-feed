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

            Section("Project Repos") {
                if appModel.projectRepos.isEmpty {
                    Text("No project repos configured yet.")
                    Text("Choose a local Git repo and Devboard can turn committed activity into colorful Daily Digest posts.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.projectRepos) { repo in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color(devboardHex: repo.accentColor))
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(repo.name)
                                        .font(.headline)

                                    Text(repo.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)

                                    Text(repo.lastSuccessfulCrawlAt.map { "Last digest run: \(DateFormatter.devboardDay.string(from: $0))" } ?? "No digest run yet.")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()

                                Toggle(
                                    "Active",
                                    isOn: Binding(
                                        get: { repo.isActive },
                                        set: { appModel.setProjectRepo(repo, isActive: $0) }
                                    )
                                )
                                .toggleStyle(.switch)

                                Button("Remove", role: .destructive) {
                                    appModel.removeProjectRepo(repo)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                HStack {
                    Button("Choose Project Repo…") {
                        appModel.chooseProjectRepo()
                    }

                    Button(appModel.isDigestRunInProgress ? "Running Digests..." : "Run Daily Digests") {
                        appModel.runDailyDigests()
                    }
                    .disabled(appModel.projectRepos.filter(\.isActive).isEmpty || appModel.isDigestRunInProgress)
                }
            }

            if let folderStatusMessage = appModel.folderStatusMessage {
                Section("Latest status") {
                    Text(folderStatusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            if let digestStatusMessage = appModel.digestStatusMessage {
                Section("Digest status") {
                    Text(digestStatusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Product stance") {
                Text("Local-first")
                Text("HTML files stay untouched")
                Text("Project timeline before file browser")
                Text("Daily target: 20:00 local Git crawl")
            }
        }
        .padding(20)
        .frame(width: 560)
    }

    private var watchedFolders: [WatchedFolder] {
        appModel.watchedFolders
    }
}
