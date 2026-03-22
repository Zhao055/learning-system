import SwiftUI

struct ZhiyaCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(ZhiyaTheme.spacingMD)
            .background(ZhiyaTheme.ivory)
            .cornerRadius(ZhiyaTheme.cornerRadius)
            .shadow(color: ZhiyaTheme.softShadowColor, radius: ZhiyaTheme.softShadowRadius, y: ZhiyaTheme.softShadowY)
    }
}

struct ZhiyaPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ZhiyaTheme.label())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ZhiyaTheme.goldenAmber)
                .cornerRadius(ZhiyaTheme.cornerRadius)
        }
    }
}

struct ZhiyaSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ZhiyaTheme.label())
                .foregroundColor(ZhiyaTheme.goldenAmber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ZhiyaTheme.goldenAmber.opacity(0.12))
                .cornerRadius(ZhiyaTheme.cornerRadius)
        }
    }
}

struct ZhiyaTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(ZhiyaTheme.body())
            .padding(14)
            .background(ZhiyaTheme.cream)
            .cornerRadius(ZhiyaTheme.cornerRadiusSM)
            .overlay(
                RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusSM)
                    .stroke(ZhiyaTheme.warmGold.opacity(0.3), lineWidth: 1)
            )
    }
}

struct SubjectBadge: View {
    let icon: String
    let name: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 14))
            Text(name)
                .font(ZhiyaTheme.caption())
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
}
