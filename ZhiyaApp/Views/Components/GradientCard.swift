import SwiftUI

struct GradientCard<Content: View>: View {
    let colors: [Color]
    let content: () -> Content

    init(colors: [Color], @ViewBuilder content: @escaping () -> Content) {
        self.colors = colors
        self.content = content
    }

    var body: some View {
        content()
            .padding(ZhiyaTheme.spacingMD)
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(ZhiyaTheme.cornerRadius)
            .shadow(color: ZhiyaTheme.softShadowColor, radius: ZhiyaTheme.softShadowRadius, y: ZhiyaTheme.softShadowY)
    }
}

struct StatBarView: View {
    let label: String
    let value: Double // 0-1
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(ZhiyaTheme.caption())
                    .foregroundColor(ZhiyaTheme.lightBrown)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(ZhiyaTheme.caption())
                    .foregroundColor(ZhiyaTheme.darkBrown)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * value, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(ZhiyaTheme.warmGold)
            Text(title)
                .font(ZhiyaTheme.heading(18))
                .foregroundColor(ZhiyaTheme.darkBrown)
            Text(message)
                .font(ZhiyaTheme.body(14))
                .foregroundColor(ZhiyaTheme.lightBrown)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
