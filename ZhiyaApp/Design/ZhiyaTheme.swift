import SwiftUI

enum ZhiyaTheme {
    // MARK: - Colors
    static let cream = Color(hex: "FFF8F0")
    static let ivory = Color(hex: "FEFCF7")
    static let goldenAmber = Color(hex: "D4A574")
    static let warmGold = Color(hex: "E8C9A0")
    static let softTeal = Color(hex: "7DB8A0")
    static let darkBrown = Color(hex: "4A3728")
    static let lightBrown = Color(hex: "8B7355")

    // Character trait colors
    static let integrity = Color(hex: "6BBF7B")     // green
    static let empathy = Color(hex: "F08080")        // coral
    static let wisdom = Color(hex: "5AAFA0")         // teal
    static let patience = Color(hex: "90D4A0")       // light green
    static let acceptance = Color(hex: "7DD4C0")     // mint
    static let passion = Color(hex: "E87BAF")        // rose

    // Subject colors
    static let mathColor = Color(hex: "4E6EF2")
    static let bioColor = Color(hex: "4CAF50")
    static let psychColor = Color(hex: "9C27B0")

    // Emotion UI colors
    static let smoothBackground = cream
    static let frustratedBackground = Color(hex: "FFF0EC")
    static let lowEnergyBackground = Color(hex: "F5F0EB")
    static let anxiousBackground = Color(hex: "F0F0F5")

    // MARK: - Fonts
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func label(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSM: CGFloat = 10
    static let cornerRadiusLG: CGFloat = 24

    // MARK: - Shadows
    static let softShadowColor = Color.black.opacity(0.06)
    static let softShadowRadius: CGFloat = 8
    static let softShadowY: CGFloat = 4

    // MARK: - Gradients
    static let goldGradient = LinearGradient(
        colors: [goldenAmber, warmGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tealGradient = LinearGradient(
        colors: [softTeal, Color(hex: "A0D4C0")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
