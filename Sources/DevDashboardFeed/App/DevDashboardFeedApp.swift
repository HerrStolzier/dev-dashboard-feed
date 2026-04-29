import SwiftUI

@main
struct DevDashboardFeedApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup("Dev Dashboard Feed") {
            ContentView(appModel: appModel)
        }

        Settings {
            SettingsView(appModel: appModel)
        }

        MenuBarExtra("Dev Dashboard Feed", systemImage: "rectangle.stack") {
            MenuBarView(
                documentCount: appModel.documents.count,
                watchedFolderCount: appModel.watchedFolders.count
            )
        }
    }
}
