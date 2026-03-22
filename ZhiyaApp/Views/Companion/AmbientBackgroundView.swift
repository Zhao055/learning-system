import SwiftUI

struct AmbientBackgroundView: View {
    @ObservedObject var emotionEngine = EmotionEngine.shared

    @State private var phase: CGFloat = 0

    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }

    private enum Season {
        case spring, summer, autumn, winter

        var image: Image {
            switch self {
            case .spring: return ZhiyaImages.bgSpring
            case .summer: return ZhiyaImages.bgSummer
            case .autumn: return ZhiyaImages.bgAutumn
            case .winter: return ZhiyaImages.bgWinter
            }
        }

        var fallbackColors: [Color] {
            switch self {
            case .spring: return [Color(hex: "F0FFF0"), Color(hex: "FEFCF7"), Color(hex: "E8F5E9")]
            case .summer: return [Color(hex: "FFF8F0"), Color(hex: "FEFCF7"), Color(hex: "F5F0EB")]
            case .autumn: return [Color(hex: "FFF3E0"), Color(hex: "FFF0E0"), Color(hex: "E8D5C0")]
            case .winter: return [Color(hex: "ECEFF1"), Color(hex: "F5F5F5"), Color(hex: "E0E0E0")]
            }
        }
    }

    private var season: Season {
        switch currentMonth {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    /// Whether seasonal images are available in the bundle
    private var hasSeasonalImages: Bool {
        ZhiyaImages.uiImage(.bgSpring) != nil
    }

    private var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .sunset
        case 20..<23: return .evening
        default: return .night
        }
    }

    private enum TimeOfDay {
        case dawn, day, sunset, evening, night

        var overlayOpacity: Double {
            switch self {
            case .dawn: return 0.1
            case .day: return 0.0
            case .sunset: return 0.15
            case .evening: return 0.25
            case .night: return 0.35
            }
        }

        var overlayColor: Color {
            switch self {
            case .dawn: return Color(hex: "FFE8D6")
            case .day: return .clear
            case .sunset: return Color(hex: "FFE0CC")
            case .evening: return Color(hex: "E8DDD0")
            case .night: return Color(hex: "D5CCC0")
            }
        }

        var fallbackColors: [Color] {
            switch self {
            case .dawn: return [Color(hex: "FFE8D6"), Color(hex: "FFF0E0"), Color(hex: "FEFCF7")]
            case .day: return [Color(hex: "FFF8F0"), Color(hex: "FEFCF7"), Color(hex: "F5F0EB")]
            case .sunset: return [Color(hex: "FFE0CC"), Color(hex: "FFF0E0"), Color(hex: "E8D5C0")]
            case .evening: return [Color(hex: "E8DDD0"), Color(hex: "F0E8E0"), Color(hex: "DDD5CC")]
            case .night: return [Color(hex: "D5CCC0"), Color(hex: "E0D8D0"), Color(hex: "C8C0B8")]
            }
        }
    }

    var body: some View {
        ZStack {
            if hasSeasonalImages {
                // Seasonal image background
                season.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                // Time-of-day overlay
                timeOfDay.overlayColor
                    .opacity(timeOfDay.overlayOpacity)
                    .ignoresSafeArea()
            } else {
                // Fallback: gradient changes with time of day
                LinearGradient(
                    colors: timeOfDay.fallbackColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            // Mood overlay
            emotionEngine.backgroundColor
                .opacity(0.3)
                .ignoresSafeArea()

            // Floating ambient elements
            GeometryReader { geo in
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(ZhiyaTheme.warmGold.opacity(0.05 + Double(i) * 0.01))
                        .frame(width: 100 + CGFloat(i) * 40)
                        .offset(
                            x: sin(phase + CGFloat(i) * 1.2) * 30,
                            y: cos(phase + CGFloat(i) * 0.8) * 20
                        )
                        .position(
                            x: geo.size.width * (0.2 + CGFloat(i) * 0.15),
                            y: geo.size.height * (0.1 + CGFloat(i) * 0.18)
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}
