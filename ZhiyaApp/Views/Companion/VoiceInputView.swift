import SwiftUI

struct VoiceInputView: View {
    @ObservedObject var speechService: SpeechService
    let onTranscription: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if speechService.permissionDenied {
                // Permission denied state
                VStack(spacing: 16) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.5))

                    Text("需要麦克风和语音识别权限")
                        .font(ZhiyaTheme.body())
                        .foregroundColor(ZhiyaTheme.darkBrown)

                    Text("请在设置中开启权限")
                        .font(ZhiyaTheme.caption(13))
                        .foregroundColor(ZhiyaTheme.lightBrown)

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("打开设置")
                            .font(ZhiyaTheme.label())
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(ZhiyaTheme.goldenAmber)
                            .cornerRadius(20)
                    }
                }
            } else {
                // Wave animation
                HStack(spacing: 4) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ZhiyaTheme.goldenAmber)
                            .frame(width: 3, height: waveHeight(index: i))
                            .animation(
                                .easeInOut(duration: 0.15),
                                value: speechService.audioLevel
                            )
                    }
                }
                .frame(height: 60)

                // Real-time transcription
                if speechService.transcription.isEmpty {
                    Text("正在听...")
                        .font(ZhiyaTheme.body())
                        .foregroundColor(ZhiyaTheme.darkBrown)
                } else {
                    ScrollView {
                        Text(speechService.transcription)
                            .font(ZhiyaTheme.body(15))
                            .foregroundColor(ZhiyaTheme.darkBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 120)
                }
            }

            // Cancel / Send buttons
            HStack(spacing: 40) {
                Button {
                    _ = speechService.stopRecording()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.6))
                }

                if !speechService.permissionDenied {
                    Button {
                        let text = speechService.stopRecording()
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onTranscription(text)
                        }
                        onDismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(speechService.transcription.isEmpty
                                ? ZhiyaTheme.goldenAmber.opacity(0.4)
                                : ZhiyaTheme.goldenAmber)
                    }
                    .disabled(speechService.transcription.isEmpty)
                }
            }

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
        .background(ZhiyaTheme.ivory.opacity(0.98))
        .onAppear {
            Task {
                let granted = await speechService.requestPermissions()
                if granted {
                    try? speechService.startRecording()
                }
            }
        }
    }

    private func waveHeight(index: Int) -> CGFloat {
        let base: CGFloat = 8
        let maxHeight: CGFloat = 40
        let phase = sin(CGFloat(index) * 0.6 + CGFloat(speechService.audioLevel) * 3)
        let level = speechService.isRecording ? CGFloat(speechService.audioLevel) : 0.1
        return base + (maxHeight - base) * abs(phase) * max(level, 0.15)
    }
}
