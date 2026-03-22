import SwiftUI

struct ZhiyaMascotView: View {
    let emotion: ZhiyaEmotion
    var size: CGFloat = 32

    @State private var swaying = false

    /// Whether the real avatar image loaded successfully
    private var hasAvatarImage: Bool {
        ZhiyaImages.uiImage(.avatar) != nil
    }

    var body: some View {
        Group {
            if hasAvatarImage {
                // Real image-based mascot
                imageBasedMascot
            } else {
                // Fallback: code-drawn mascot (original)
                codeMascot
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                swaying = true
            }
        }
    }

    // MARK: - Image-based Mascot

    private var imageBasedMascot: some View {
        ZhiyaImages.avatar
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .rotationEffect(.degrees(swaying ? 2 : -2))
            .opacity(emotion == .sleeping ? 0.7 : 1.0)
            .saturation(emotion == .sleeping ? 0.6 : 1.0)
            .overlay(
                // Emotion indicator overlay for small sizes
                emotionBadge
                    .opacity(size >= 40 ? 1 : 0)
            )
    }

    @ViewBuilder
    private var emotionBadge: some View {
        switch emotion {
        case .sleeping:
            Text("z")
                .font(.system(size: size * 0.2, weight: .light))
                .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.6))
                .offset(x: size * 0.3, y: -size * 0.3)
        case .happy, .excited:
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15))
                .foregroundColor(ZhiyaTheme.goldenAmber)
                .offset(x: size * 0.35, y: -size * 0.35)
        case .caring:
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.12))
                .foregroundColor(ZhiyaTheme.empathy.opacity(0.6))
                .offset(x: size * 0.35, y: -size * 0.3)
        default:
            EmptyView()
        }
    }

    // MARK: - Code-drawn Fallback

    @State private var blinking = false

    private var codeMascot: some View {
        ZStack {
            // Body - leaf shape
            Ellipse()
                .fill(leafGradient)
                .frame(width: size, height: size * 1.3)
                .rotationEffect(.degrees(swaying ? 3 : -3))

            // Eyes
            HStack(spacing: size * 0.15) {
                Eye(size: size * 0.18, emotion: emotion, blinking: blinking)
                Eye(size: size * 0.18, emotion: emotion, blinking: blinking)
            }
            .offset(y: -size * 0.1)

            // Mouth (visible at larger sizes)
            if size >= 60 {
                mouthShape
                    .offset(y: size * 0.15)
            }

            // Leaf on top
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.3))
                .foregroundColor(Color(hex: "8BC34A"))
                .offset(x: size * 0.15, y: -size * 0.55)
                .rotationEffect(.degrees(swaying ? 10 : -5))
        }
        .onAppear { startBlinking() }
    }

    private var leafGradient: LinearGradient {
        let baseColor: Color = {
            switch emotion {
            case .caring: return Color(hex: "A8D5BA")
            case .happy, .excited: return Color(hex: "7BC88F")
            case .sleeping: return Color(hex: "C5DEC0")
            default: return Color(hex: "8FD4A4")
            }
        }()

        return LinearGradient(
            colors: [baseColor.opacity(0.8), baseColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var mouthShape: some View {
        switch emotion {
        case .happy, .excited:
            HalfCircle()
                .stroke(Color(hex: "4A3728"), lineWidth: size * 0.02)
                .frame(width: size * 0.2, height: size * 0.08)
        case .caring:
            Ellipse()
                .fill(Color(hex: "4A3728").opacity(0.3))
                .frame(width: size * 0.1, height: size * 0.06)
        case .sleeping:
            Text("z")
                .font(.system(size: size * 0.12, weight: .light))
                .foregroundColor(Color(hex: "4A3728").opacity(0.4))
        default:
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "4A3728").opacity(0.3))
                .frame(width: size * 0.12, height: size * 0.015)
        }
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...6), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { blinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { blinking = false }
            }
        }
    }
}

private struct Eye: View {
    let size: CGFloat
    let emotion: ZhiyaEmotion
    let blinking: Bool

    var body: some View {
        Group {
            if blinking || emotion == .sleeping {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "4A3728"))
                    .frame(width: size, height: 2)
            } else {
                switch emotion {
                case .happy, .excited:
                    HalfCircle()
                        .fill(Color(hex: "4A3728"))
                        .frame(width: size, height: size * 0.5)
                case .caring:
                    Circle()
                        .fill(Color(hex: "4A3728"))
                        .frame(width: size * 0.85, height: size * 0.85)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: size * 0.3)
                                .offset(x: -size * 0.1, y: -size * 0.1)
                        )
                default:
                    Circle()
                        .fill(Color(hex: "4A3728"))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.6))
                                .frame(width: size * 0.35)
                                .offset(x: -size * 0.1, y: -size * 0.1)
                        )
                }
            }
        }
    }
}

private struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                    radius: rect.width / 2,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack(spacing: 20) {
        ZhiyaMascotView(emotion: .gazing, size: 40)
        ZhiyaMascotView(emotion: .happy, size: 40)
        ZhiyaMascotView(emotion: .caring, size: 40)
        ZhiyaMascotView(emotion: .thinking, size: 40)
        ZhiyaMascotView(emotion: .sleeping, size: 40)
    }
    .padding()
    .background(ZhiyaTheme.cream)
}
