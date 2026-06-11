import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Trailhead design language
//
// A warm, outdoorsy palette: pine green primary, trail amber accent,
// bone surfaces in light mode, deep forest in dark. Shared 1:1 with the
// Android app (see ui/theme/Color.kt) to keep the two platforms in parity.

extension Color {

    // Brand constants (same hex on both platforms)
    static let trailPine     = Color(hex: 0x2E5D3B)   // primary
    static let trailPineDeep = Color(hex: 0x1E4429)   // gradient end / pressed
    static let trailAmber    = Color(hex: 0xE8A33D)   // accent
    static let trailBone     = Color(hex: 0xF7F4EC)   // light surface
    static let trailForest   = Color(hex: 0x14201A)   // dark background

    /// App background — bone in light, deep forest in dark.
    static let trailBackground = Color(
        light: Color(hex: 0xF7F4EC),
        dark:  Color(hex: 0x14201A)
    )

    /// Raised card surface — pure-ish white on bone, lifted forest in dark.
    static let trailCard = Color(
        light: Color(hex: 0xFFFFFF),
        dark:  Color(hex: 0x1E2D24)
    )

    /// Primary that stays legible in both schemes (slightly lighter in dark).
    static let trailPrimary = Color(
        light: Color(hex: 0x2E5D3B),
        dark:  Color(hex: 0x6FBF87)
    )

    /// Hairline / divider tint.
    static let trailHairline = Color(
        light: Color(hex: 0x2E5D3B).opacity(0.10),
        dark:  Color(hex: 0xFFFFFF).opacity(0.08)
    )
}

extension LinearGradient {
    /// Pine → deep pine, used on the hero classification card.
    static let trailHero = LinearGradient(
        colors: [Color.trailPine, Color.trailPineDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Reusable surfaces

/// A soft, rounded, elevated card — the standard container for the redesign.
struct TrailCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.trailCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.trailHairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

extension View {
    /// Wraps the view in the standard Trailhead card surface.
    func trailCard(padding: CGFloat = 16) -> some View {
        TrailCard(padding: padding) { self }
    }
}

// MARK: - Color helpers

extension Color {
    /// Hex initializer, e.g. `Color(hex: 0x2E5D3B)`.
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255
        )
    }

    /// Light/dark adaptive color that resolves at render time.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(dark) : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}
