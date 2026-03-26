import SwiftUI

/// Chat bubble with explicit width constraint.
/// Key fix: receives `availableWidth` from parent (via GeometryReader),
/// uses `.frame(maxWidth:)` instead of fixedSize/Spacer/layoutPriority.
struct ChatBubbleView: View {
    let message: ChatMessage
    let availableWidth: CGFloat

    private var isUser: Bool { message.role == .user }
    private var maxBubbleWidth: CGFloat { availableWidth * 0.75 }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser {
                ZhiyaAvatarSmall()
                    .offset(y: 4)
            }

            Text(message.content + (message.isStreaming ? "▍" : ""))
                .font(ZhiyaTheme.body(15))
                .foregroundColor(isUser ? .white : ZhiyaTheme.darkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
                .background(isUser ? ZhiyaTheme.goldenAmber : ZhiyaTheme.bubbleGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 12)
    }
}

/// Minimal Zhiya avatar for chat bubbles (24pt green circle with leaf).
struct ZhiyaAvatarSmall: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ZhiyaTheme.zhiyaGreen)
                .frame(width: 24, height: 24)
            Text("🌱")
                .font(.system(size: 12))
        }
    }
}

// Custom corner radius helper
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
