import SwiftUI

struct MenuBarView: View {
    let documentCount: Int
    let watchedFolderCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dev Dashboard Feed")
                .font(.headline)

            Text("\(watchedFolderCount) watched folder(s) configured")
                .foregroundStyle(.secondary)
            Text("\(documentCount) sample documents loaded")
                .foregroundStyle(.secondary)

            Divider()

            Text("Next milestone")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Wire the stored folders into HTML scanning and feed indexing.")
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
