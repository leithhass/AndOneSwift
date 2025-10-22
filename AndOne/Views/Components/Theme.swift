import SwiftUI

// Palette
extension Color {
    static let andOrange = Color(red: 1.00, green: 0.42, blue: 0.00)      // #FF6A00 (accent)
    static let andOrangeSoft = Color(red: 1.00, green: 0.83, blue: 0.75)   // ~#FFE6D6 (badges)
    static let andInk = Color(.label)
    static let andMuted = Color(.secondaryLabel)
    static let andCardBG = Color(.systemBackground)
    static let andDanger = Color(.systemRed)
    static let andSuccess = Color(.systemGreen)
    static let andInfo = Color(.systemIndigo)

    // ✅ Ajouts (réutilisables partout)
    static let andSurface = Color(UIColor.systemGroupedBackground) // fond app par défaut
    static let andMint = Color(red: 0.36, green: 0.72, blue: 0.68)     // 3e couleur (vert doux)
    static let andBlueGray = Color(red: 0.34, green: 0.42, blue: 0.56) // alternative sobre
}


// Carte standard
extension View {
    func andCard() -> some View {
        self.padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// Press effect
struct PressEffect: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.03 : 0.06), radius: 6, x: 0, y: 3)
    }
}

// Pill générique
struct Pill: View {
    let text: String
    let icon: String?
    let fg: Color
    let bg: Color
    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.caption) }
            Text(text).font(.caption).bold()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(bg, in: Capsule())
        .foregroundStyle(fg)
    }
}

// Progress ring très léger pour “places remplies”
struct TinyProgressRing: View {
    let progress: CGFloat // 0...1
    var body: some View {
        ZStack {
            Circle().stroke(Color.andOrange.opacity(0.2), lineWidth: 3)
            Circle().trim(from: 0, to: progress)
                .stroke(Color.andOrange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

// Toast simple
struct Toast: View {
    let text: String
    let systemName: String
    let tint: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
            Text(text).font(.callout).bold()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.5)))
        .foregroundStyle(tint)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
