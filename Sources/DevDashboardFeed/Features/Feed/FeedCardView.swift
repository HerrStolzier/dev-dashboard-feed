import SwiftUI

struct FeedCardView: View {
    let document: DocumentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                if document.sourceKind == .dailyDigest {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: accentColor.opacity(0.7), radius: 4)
                        .padding(.top, 5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(document.title)
                            .font(.headline)
                            .lineLimit(2)

                        if document.sourceKind == .dailyDigest {
                            Text("Daily Digest")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .foregroundStyle(accentColor)
                                .background(accentColor.opacity(0.14), in: Capsule())
                        }
                    }

                    Text(document.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            HStack {
                Label(document.project, systemImage: document.sourceKind == .dailyDigest ? "sparkles.rectangle.stack" : "folder")
                Spacer()
                Text(document.relativeTimestamp)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: document.sourceKind == .dailyDigest ? 1 : 0)
        }
        .padding(.vertical, 4)
    }

    private var accentColor: Color {
        Color(devboardHex: document.accentColor ?? "#38bdf8")
    }

    private var cardBackground: some ShapeStyle {
        if document.sourceKind == .dailyDigest {
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0.16),
                        Color.black.opacity(0.18),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(Color.clear)
        }
    }

    private var borderColor: Color {
        document.sourceKind == .dailyDigest ? accentColor.opacity(0.35) : .clear
    }
}
