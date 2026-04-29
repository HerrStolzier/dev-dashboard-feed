import SwiftUI

struct MenuBarView: View {
    let documentCount: Int
    let watchedFolderCount: Int
    let projectRepoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dev Dashboard Feed")
                .font(.headline)

            Text("\(watchedFolderCount) watched folder(s) configured")
                .foregroundStyle(.secondary)
            Text("\(projectRepoCount) project repo(s) configured")
                .foregroundStyle(.secondary)
            Text("\(documentCount) feed item(s) loaded")
                .foregroundStyle(.secondary)

            Divider()

            Text("Next milestone")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Package the 20:00 background digest runner as a real macOS helper.")
                .foregroundStyle(.secondary)

            Divider()

            SettingsLink {
                Label("Open Settings", systemImage: "gearshape")
            }
        }
        .padding()
        .frame(width: 280)
    }
}
