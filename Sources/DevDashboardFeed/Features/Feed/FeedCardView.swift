import SwiftUI

struct FeedCardView: View {
    let document: DocumentItem
    var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                pixelIcon

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(document.title)
                            .font(.system(.headline, design: .rounded).weight(.black))
                            .foregroundStyle(PixelpunkTheme.ink)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }

                    Text(document.summary)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(PixelpunkTheme.muted)
                        .lineLimit(3)
                }
            }

            HStack(spacing: 6) {
                PixelpunkBadge(text: sourceLabel, accent: accentColor)
                PixelpunkBadge(text: "LVL \(level)", accent: PixelpunkTheme.amber)

                Spacer()

                Text(document.relativeTimestamp)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(PixelpunkTheme.muted)
                    .lineLimit(1)
            }

            HStack(spacing: 7) {
                Image(systemName: document.sourceKind == .dailyDigest ? "sparkles.rectangle.stack.fill" : "folder.fill")
                Text(document.project)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(xp) XP")
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(accentColor.opacity(0.95))
        }
        .padding(13)
        .pixelpunkPanel(
            accent: accentColor,
            isRaised: document.sourceKind == .dailyDigest,
            isSelected: isSelected
        )
        .contentShape(RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius))
    }

    private var pixelIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
                .fill(accentColor.opacity(0.18))
                .frame(width: 34, height: 34)

            Image(systemName: document.sourceKind == .dailyDigest ? "bolt.fill" : "doc.text.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(accentColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
                .stroke(accentColor.opacity(0.65), lineWidth: 1)
        }
        .shadow(color: accentColor.opacity(0.35), radius: 8)
    }

    private var accentColor: Color {
        Color(devboardHex: document.accentColor ?? "#38bdf8")
    }

    private var sourceLabel: String {
        document.sourceKind == .dailyDigest ? "Quest Log" : "Artifact"
    }

    private var level: Int {
        max(1, min(99, document.title.count / 4 + (document.sourceKind == .dailyDigest ? 8 : 1)))
    }

    private var xp: Int {
        max(25, min(999, document.summary.count * (document.sourceKind == .dailyDigest ? 3 : 1)))
    }
}
