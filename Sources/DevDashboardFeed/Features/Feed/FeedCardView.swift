import SwiftUI

struct FeedCardView: View {
    let document: DocumentItem
    var isSelected = false

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    pixelIcon

                    VStack(alignment: .leading, spacing: 7) {
                        Text(document.title)
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(PixelpunkTheme.ink)
                            .lineLimit(2)

                        Text(document.summary)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
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
            .padding(.trailing, isSelected ? 7 : 0)
            .pixelpunkPanel(
                accent: accentColor,
                isRaised: document.sourceKind == .dailyDigest,
                isSelected: isSelected
            )

            if isSelected {
                selectionTab
                    .offset(x: 8)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius))
    }

    private var pixelIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.18))
                .frame(width: 42, height: 42)

            Image(systemName: document.sourceKind == .dailyDigest ? "bolt.fill" : "doc.text.fill")
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(accentColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(accentColor.opacity(0.65), lineWidth: 1)
        }
        .shadow(color: accentColor.opacity(0.35), radius: 8)
    }

    private var selectionTab: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 12, y: 9))
            path.addLine(to: CGPoint(x: 12, y: 25))
            path.addLine(to: CGPoint(x: 0, y: 34))
            path.closeSubpath()
        }
        .fill(accentColor)
        .frame(width: 12, height: 34)
        .shadow(color: accentColor.opacity(0.6), radius: 8)
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
