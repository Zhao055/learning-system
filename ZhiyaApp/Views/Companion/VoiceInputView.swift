import SwiftUI

struct VoiceInputView: View {
    @Binding var isRecording: Bool
    let onTranscription: (String) -> Void

    @State private var wavePhase: CGFloat = 0
    @State private var amplitude: CGFloat = 0.3

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Wave animation
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ZhiyaTheme.goldenAmber)
                        .frame(width: 3, height: waveHeight(index: i))
                        .animation(
                            .easeInOut(duration: 0.3 + Double(i % 5) * 0.1)
                            .repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
            }
            .frame(height: 60)

            Text("正在听...")
                .font(ZhiyaTheme.body())
                .foregroundColor(ZhiyaTheme.darkBrown)

            // Cancel / Send buttons
            HStack(spacing: 40) {
                Button {
                    isRecording = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.6))
                }

                Button {
                    // TODO: Implement actual speech recognition
                    isRecording = false
                    onTranscription("（语音输入功能开发中）")
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(ZhiyaTheme.goldenAmber)
                }
            }

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .background(ZhiyaTheme.ivory.opacity(0.98))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                amplitude = 0.8
            }
        }
    }

    private func waveHeight(index: Int) -> CGFloat {
        let base: CGFloat = 8
        let maxHeight: CGFloat = 40
        let phase = sin(CGFloat(index) * 0.6 + wavePhase)
        return base + (maxHeight - base) * abs(phase) * (isRecording ? amplitude : 0.1)
    }
}
