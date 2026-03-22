import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            if !isUser {
                ZhiyaMascotView(emotion: EmotionEngine.shared.zhiyaEmotion, size: 20)
                    .offset(y: 4)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Text(message.content + (message.isStreaming ? "▍" : ""))
                    .font(ZhiyaTheme.body(15))
                    .foregroundColor(isUser ? .white : ZhiyaTheme.darkBrown)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? ZhiyaTheme.goldenAmber : ZhiyaTheme.ivory)
                    .cornerRadius(16)
                    .cornerRadius(isUser ? 16 : 4, corners: isUser ? [.bottomRight] : [.bottomLeft])
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// Custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
