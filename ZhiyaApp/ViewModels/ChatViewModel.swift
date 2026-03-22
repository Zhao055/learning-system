import SwiftUI

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false

    private var systemPrompt: String

    init(systemPrompt: String) {
        self.systemPrompt = systemPrompt
    }

    @MainActor
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        EmotionEngine.shared.updateForChatState(.thinking)

        let assistantId = UUID().uuidString
        let placeholder = ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true)
        messages.append(placeholder)

        Task {
            do {
                let stream = AIService.shared.streamChat(messages: messages.dropLast().map { $0 }, systemPrompt: systemPrompt)
                for try await chunk in stream {
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content += chunk
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
                EmotionEngine.shared.updateForChatState(.idle)
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].content = "抱歉，出了点问题：\(error.localizedDescription)"
                    messages[idx].isStreaming = false
                }
            }
            isLoading = false
        }
    }
}
