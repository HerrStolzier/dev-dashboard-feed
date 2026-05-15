import SwiftUI

enum PixelpunkTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let panel = Color(red: 0.08, green: 0.08, blue: 0.13)
    static let panelRaised = Color(red: 0.11, green: 0.10, blue: 0.17)
    static let ink = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let muted = Color(red: 0.60, green: 0.65, blue: 0.76)
    static let cyan = Color(red: 0.22, green: 0.86, blue: 1.0)
    static let magenta = Color(red: 1.0, green: 0.34, blue: 0.78)
    static let green = Color(red: 0.26, green: 0.96, blue: 0.62)
    static let amber = Color(red: 1.0, green: 0.78, blue: 0.25)
    static let border = Color.white.opacity(0.14)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, magenta, green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var appBackground: some View {
        ZStack {
            background

            RadialGradient(
                colors: [cyan.opacity(0.28), .clear],
                center: .topLeading,
                startRadius: 40,
                endRadius: 520
            )

            RadialGradient(
                colors: [magenta.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 60,
                endRadius: 620
            )
        }
    }
}

struct PixelpunkPanel: ViewModifier {
    var accent: Color = PixelpunkTheme.cyan
    var isRaised = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRaised ? PixelpunkTheme.panelRaised : PixelpunkTheme.panel)

                    Rectangle()
                        .fill(accent)
                        .frame(height: 3)
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(accent.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: accent.opacity(isRaised ? 0.25 : 0.12), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func pixelpunkPanel(accent: Color = PixelpunkTheme.cyan, isRaised: Bool = false) -> some View {
        modifier(PixelpunkPanel(accent: accent, isRaised: isRaised))
    }
}

struct PixelpunkButtonStyle: ButtonStyle {
    var accent: Color = PixelpunkTheme.cyan

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .monospaced).weight(.black))
            .textCase(.uppercase)
            .foregroundStyle(PixelpunkTheme.background)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(accent.opacity(configuration.isPressed ? 0.75 : 1.0), in: RoundedRectangle(cornerRadius: 5))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(height: configuration.isPressed ? 1 : 3)
                    .padding(.horizontal, 3)
            }
            .shadow(color: accent.opacity(configuration.isPressed ? 0.12 : 0.35), radius: configuration.isPressed ? 4 : 12, y: 6)
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}

struct PixelpunkBadge: View {
    let text: String
    var accent: Color = PixelpunkTheme.cyan

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .textCase(.uppercase)
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 3))
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(accent.opacity(0.65), lineWidth: 1)
            }
    }
}
