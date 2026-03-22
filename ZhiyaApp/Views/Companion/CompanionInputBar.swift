import SwiftUI

struct CompanionInputBar: View {
    @Binding var inputText: String
    let isLoading: Bool
    let onSend: () -> Void
    let onCamera: () -> Void
    let onVoice: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(ZhiyaTheme.warmGold.opacity(0.3))

            HStack(spacing: 10) {
                // Camera button
                Button(action: onCamera) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ZhiyaTheme.lightBrown)
                        .frame(width: 36, height: 36)
                }

                // Text field
                HStack(spacing: 8) {
                    TextField("和知芽聊聊...", text: $inputText, axis: .vertical)
                        .font(ZhiyaTheme.body(15))
                        .lineLimit(1...5)
                        .focused($isFocused)
                        .onSubmit {
                            if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                                onSend()
                            }
                        }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(ZhiyaTheme.cream)
                .cornerRadius(20)

                // Voice / Send toggle
                if inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: onVoice) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ZhiyaTheme.lightBrown)
                            .frame(width: 36, height: 36)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isLoading ? ZhiyaTheme.warmGold.opacity(0.4) : ZhiyaTheme.goldenAmber)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ZhiyaTheme.cream.opacity(0.95))
            .shadow(color: ZhiyaTheme.warmGold.opacity(0.1), radius: 4, y: -2)
        }
    }
}
