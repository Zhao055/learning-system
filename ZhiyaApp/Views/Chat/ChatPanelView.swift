import SwiftUI

struct ChatPanelView: View {
    @StateObject private var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    init(systemPrompt: String) {
        _vm = StateObject(wrappedValue: ChatViewModel(systemPrompt: systemPrompt))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ZhiyaMascotView(emotion: EmotionEngine.shared.zhiyaEmotion, size: 24)
                Text("知芽")
                    .font(ZhiyaTheme.heading(16))
                    .foregroundColor(ZhiyaTheme.darkBrown)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ZhiyaTheme.lightBrown)
                        .font(.system(size: 22))
                }
            }
            .padding()

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 10) {
                TextField("向知芽提问...", text: $vm.inputText)
                    .font(ZhiyaTheme.body(15))
                    .padding(10)
                    .background(ZhiyaTheme.cream)
                    .cornerRadius(20)

                Button {
                    vm.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? ZhiyaTheme.warmGold.opacity(0.4) : ZhiyaTheme.goldenAmber)
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(ZhiyaTheme.ivory)
        }
    }
}
