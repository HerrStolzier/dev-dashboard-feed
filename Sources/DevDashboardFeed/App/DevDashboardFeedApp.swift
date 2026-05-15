import SwiftUI

@main
struct DevDashboardFeedApp: App {
    @State private var appModel: AppModel

    init() {
        DigestCLI.runIfRequested()
        _appModel = State(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup("Dev Dashboard Feed") {
            ContentView(appModel: appModel)
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView(appModel: appModel)
        }

        MenuBarExtra("Dev Dashboard Feed", systemImage: "rectangle.stack") {
            MenuBarView(
                documentCount: appModel.documents.count,
                watchedFolderCount: appModel.watchedFolders.count,
                projectRepoCount: appModel.projectRepos.count
            )
        }
    }
}
