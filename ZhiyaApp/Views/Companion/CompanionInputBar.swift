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
                        .foregroundColor(Color(hex: "E8C9A0"))
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
                .background(Color.white)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "D4A574").opacity(0.4), lineWidth: 1))

                // Voice / Send toggle
                if inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: onVoice) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "E8C9A0"))
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
            .background(Color(hex: "4A3728"))
            .shadow(color: ZhiyaTheme.warmGold.opacity(0.15), radius: 6, y: -2)
        }
    }
}
