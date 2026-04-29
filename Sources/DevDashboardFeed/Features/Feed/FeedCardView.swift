import SwiftUI

struct FeedCardView: View {
    let document: DocumentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(document.title)
                .font(.headline)

            Text(document.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(document.project, systemImage: "folder")
                Spacer()
                Text(document.relativeTimestamp)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
