import SwiftUI

struct CelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Warm backdrop — use celebration image if available
            Group {
                if ZhiyaImages.uiImage(.bgCelebration) != nil {
                    ZhiyaImages.bgCelebration
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .overlay(Color.black.opacity(0.15))
                } else {
                    Color.black.opacity(0.3)
                }
            }
            .ignoresSafeArea()
            .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                Spacer()

                // Mascot excited
                ZhiyaMascotView(emotion: .excited, size: 80)
                    .scaleEffect(scale)

                // Milestone message
                VStack(spacing: 12) {
                    Text(milestone.title)
                        .font(ZhiyaTheme.title(28))
                        .foregroundColor(ZhiyaTheme.darkBrown)

                    Text(milestone.description)
                        .font(ZhiyaTheme.body())
                        .foregroundColor(ZhiyaTheme.lightBrown)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .opacity(opacity)

                Spacer()

                // Dismiss
                Button("继续") { onDismiss() }
                    .font(ZhiyaTheme.label())
                    .foregroundColor(ZhiyaTheme.goldenAmber)
                    .padding(.bottom, 60)
                    .opacity(opacity)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusLG)
                    .fill(ZhiyaTheme.ivory)
                    .shadow(radius: 20)
            )
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { scale = 1.0 }
            withAnimation(.easeIn(duration: 0.4).delay(0.3)) { opacity = 1.0 }
        }
    }
}
