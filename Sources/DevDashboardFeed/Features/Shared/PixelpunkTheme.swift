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
    static let cornerRadius: CGFloat = 5
    static let detailMaxWidth: CGFloat = 1120

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

    static func accent(for document: DocumentItem) -> Color {
        Color(devboardHex: document.accentColor ?? "#38bdf8")
    }
}

struct PixelpunkProjectTheme {
    let accent: Color
    let glow: Color
    let background: Color

    init(accent: Color, glow: Color? = nil, background: Color = PixelpunkTheme.background) {
        self.accent = accent
        self.glow = glow ?? accent
        self.background = background
    }

    static func theme(for document: DocumentItem?) -> PixelpunkProjectTheme {
        guard let document else {
            return PixelpunkProjectTheme(accent: PixelpunkTheme.cyan)
        }

        return PixelpunkProjectTheme(accent: PixelpunkTheme.accent(for: document))
    }
}

struct PixelpunkAppFrame<Content: View>: View {
    let theme: PixelpunkProjectTheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                ZStack {
                    theme.background

                    RadialGradient(
                        colors: [theme.glow.opacity(0.24), .clear],
                        center: .bottomTrailing,
                        startRadius: 40,
                        endRadius: 680
                    )

                    pixelGrid
                        .opacity(0.26)
                }
            )
            .overlay {
                Rectangle()
                    .stroke(Color.black.opacity(0.78), lineWidth: 8)
            }
            .overlay {
                Rectangle()
                    .stroke(PixelpunkTheme.border, lineWidth: 1)
                    .padding(7)
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.black.opacity(0.34))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                    .padding(.top, 42)
            }
    }

    private var pixelGrid: some View {
        Canvas { context, size in
            let step: CGFloat = 8
            var path = Path()

            var x: CGFloat = 0
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }

            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }

            context.stroke(path, with: .color(Color.white.opacity(0.045)), lineWidth: 1)
        }
    }
}

struct PixelpunkPanel: ViewModifier {
    var accent: Color = PixelpunkTheme.cyan
    var isRaised = false
    var isSelected = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
                        .fill(panelFill)

                    Rectangle()
                        .fill(accent)
                        .frame(height: 3)

                    Rectangle()
                        .fill(accent.opacity(0.65))
                        .frame(width: isSelected ? 5 : 0)
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius)
                    .stroke(isSelected ? accent.opacity(0.9) : PixelpunkTheme.border, lineWidth: 1)
            }
            .shadow(color: accent.opacity(isRaised || isSelected ? 0.22 : 0.08), radius: isRaised || isSelected ? 14 : 8, x: 0, y: 7)
    }

    private var panelFill: some ShapeStyle {
        if isSelected {
            AnyShapeStyle(
                LinearGradient(
                    colors: [accent.opacity(0.22), PixelpunkTheme.panelRaised],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(isRaised ? PixelpunkTheme.panelRaised : PixelpunkTheme.panel)
        }
    }
}

struct PixelpunkModule<Content: View>: View {
    let title: String
    var icon: String?
    var accent: Color
    var isCompact = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
                    .textCase(.uppercase)

                Spacer()

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(PixelpunkTheme.muted)
                }
            }

            content
        }
        .padding(isCompact ? 12 : 16)
        .pixelpunkPanel(accent: accent, isRaised: false)
    }
}

extension View {
    func pixelpunkPanel(accent: Color = PixelpunkTheme.cyan, isRaised: Bool = false, isSelected: Bool = false) -> some View {
        modifier(PixelpunkPanel(accent: accent, isRaised: isRaised, isSelected: isSelected))
    }
}

struct PixelpunkButtonStyle: ButtonStyle {
    var accent: Color = PixelpunkTheme.cyan
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let activeAccent = isEnabled ? accent : PixelpunkTheme.muted
        configuration.label
            .font(.system(.callout, design: .monospaced).weight(.black))
            .textCase(.uppercase)
            .foregroundStyle(isEnabled ? PixelpunkTheme.background : PixelpunkTheme.panel)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(activeAccent.opacity(configuration.isPressed ? 0.75 : 1.0), in: RoundedRectangle(cornerRadius: PixelpunkTheme.cornerRadius))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(height: configuration.isPressed ? 1 : 3)
                    .padding(.horizontal, 3)
            }
            .shadow(color: activeAccent.opacity(isEnabled ? (configuration.isPressed ? 0.12 : 0.35) : 0), radius: configuration.isPressed ? 4 : 12, y: 6)
            .opacity(isEnabled ? 1.0 : 0.42)
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
