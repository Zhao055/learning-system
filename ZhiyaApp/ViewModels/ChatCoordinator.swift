import SwiftUI

/// Handles message sending, streaming, and persistence.
/// Supports hybrid mode: Synapse (server) → Direct (MiniMax) fallback.
@MainActor
final class ChatCoordinator: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false

    private let messagesKey = "zhiya_companion_messages"

    init() {
        loadMessages()
    }

    // MARK: - Send Text Message

    func sendMessage(_ text: String, companionEngine: CompanionEngine) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true

        ConversationMemoryService.shared.analyzeAndStore(message: userMessage)
        EmotionEngine.shared.detectMoodFromText(text)
        EmotionEngine.shared.updateForChatState(.thinking)

        let assistantId = UUID().uuidString
        let placeholder = ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true)
        messages.append(placeholder)

        Task {
            do {
                let mode = AIMode.current
                let synapseReachable = await NetworkMonitor.shared.isSynapseReachable()
                let hasApiKey = AIService.shared.apiKey != nil

                switch mode {
                case .server:
                    // 强制服务器模式
                    guard synapseReachable else {
                        throw AIError.invalidURL
                    }
                    let chatMessages = buildSynapseMessages()
                    let stream = await SynapseAPI.shared.chatStream(
                        messages: chatMessages,
                        personaId: "zhiya"
                    )
                    for try await chunk in stream {
                        if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                            messages[idx].content += chunk
                        }
                    }

                case .direct:
                    // 强制 SDK 直连模式
                    guard hasApiKey else {
                        throw AIError.noApiKey
                    }
                    try await streamDirect(assistantId: assistantId, companionEngine: companionEngine)

                case .auto:
                    // 自动：Synapse → MiniMax → 离线
                    if !synapseReachable && !hasApiKey {
                        let reply = Self.localReply(for: text)
                        for char in reply {
                            try await Task.sleep(nanoseconds: 30_000_000)
                            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                                messages[idx].content.append(char)
                            }
                        }
                    } else if synapseReachable {
                        let chatMessages = buildSynapseMessages()
                        let stream = await SynapseAPI.shared.chatStream(
                            messages: chatMessages,
                            personaId: "zhiya"
                        )
                        for try await chunk in stream {
                            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                                messages[idx].content += chunk
                            }
                        }
                    } else {
                        try await streamDirect(assistantId: assistantId, companionEngine: companionEngine)
                    }
                }

                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
                EmotionEngine.shared.updateForChatState(.idle)
            } catch is CancellationError {
                // Timeout or cancellation — keep any partial content already received
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    if messages[idx].content.isEmpty {
                        messages[idx].content = "AI 回复超时，请稍后再试。"
                    }
                    messages[idx].isStreaming = false
                }
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].content = messages[idx].content.isEmpty
                        ? "抱歉，AI 暂时不可用。请在设置中配置 API Key 或 Synapse 服务器。"
                        : messages[idx].content
                    messages[idx].isStreaming = false
                }
            }
            isLoading = false
            saveMessages()
        }
    }

    // MARK: - Send Image

    func sendImage(_ imageData: Data) {
        let userMessage = ChatMessage(
            role: .user, content: "📷 [拍了一张照片]",
            messageType: .imageAnalysis, imageData: imageData
        )
        messages.append(userMessage)
        isLoading = true

        let assistantId = UUID().uuidString
        let placeholder = ChatMessage(id: assistantId, role: .assistant, content: "", isStreaming: true)
        messages.append(placeholder)

        Task {
            do {
                let contextMessages = Array(messages
                    .filter { $0.role != .system && !$0.isStreaming }
                    .suffix(10))
                let stream = AIService.shared.streamChat(
                    messages: contextMessages,
                    systemPrompt: AIService.shared.solverSystemPrompt()
                )
                for try await chunk in stream {
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content += chunk
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].isStreaming = false
                }
            } catch {
                if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                    messages[idx].content = "抱歉，分析图片时出了问题：\(error.localizedDescription)"
                    messages[idx].isStreaming = false
                }
            }
            isLoading = false
            saveMessages()
        }
    }

    // MARK: - Append Helper

    func appendAssistantMessage(_ content: String, type: MessageType, suggestionData: SuggestionData? = nil) {
        let message = ChatMessage(
            role: .assistant, content: content, messageType: type,
            suggestionData: suggestionData
        )
        messages.append(message)
        saveMessages()
    }

    // MARK: - Persistence

    func saveMessages() {
        let toSave = Array(messages.suffix(200))
        if let data = try? JSONEncoder().encode(toSave) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        // Clean up stuck streaming messages from previous sessions
        messages = decoded.map { msg in
            var m = msg
            if m.isStreaming {
                m.isStreaming = false
                if m.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    m.content = "（连接中断，请重新发送）"
                }
            }
            return m
        }
    }

    // MARK: - Direct Streaming Helper

    private func streamDirect(assistantId: String, companionEngine: CompanionEngine) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await Task.sleep(for: .seconds(30))
                throw AIError.timeout
            }
            group.addTask { @MainActor [self] in
                let systemPrompt = buildDirectSystemPrompt(companionEngine: companionEngine)
                let contextMessages = Array(messages
                    .filter { $0.role != .system && !$0.isStreaming }
                    .suffix(20))
                let stream = AIService.shared.streamChat(
                    messages: contextMessages,
                    systemPrompt: systemPrompt
                )
                for try await chunk in stream {
                    if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[idx].content += chunk
                    }
                }
            }
            try await group.next()
            group.cancelAll()
        }
    }

    // MARK: - Message Building

    private func buildSynapseMessages() -> [[String: String]] {
        messages
            .filter { $0.role != .system && !$0.isStreaming }
            .suffix(20)
            .map { ["role": $0.role.rawValue, "content": $0.content] }
    }

    // MARK: - Local Fallback (no AI configured)

    static func localReply(for userText: String) -> String {
        let lower = userText.lowercased()
        if lower.contains("不想学") || lower.contains("累") || lower.contains("烦") {
            return "没关系，休息也是成长的一部分。什么时候想回来，我都在。"
        }
        if lower.contains("做题") || lower.contains("练习") || lower.contains("出题") {
            return "好的！点击下方的建议按钮，我可以给你出一道题。（提示：在设置中配置 API Key 可以解锁完整 AI 对话）"
        }
        if lower.contains("你好") || lower.contains("hi") || lower.contains("嗨") {
            return "你好呀！很高兴见到你 🌱（提示：在设置中配置 API Key 可以和我自由聊天哦）"
        }
        let replies = [
            "我听到你了。（目前是离线模式，在设置中配置 API Key 可以解锁完整对话）",
            "嗯嗯，我在呢。去设置里配一下 API Key，我们就能好好聊了 🌱",
            "收到！不过现在我只能做简单回复。配置好 API Key 后就能自由对话啦。",
        ]
        return replies[abs(userText.hashValue) % replies.count]
    }

    private func buildDirectSystemPrompt(companionEngine: CompanionEngine) -> String {
        let profile = companionEngine.profile
        let stats = ProgressService.shared.getTotalStats()

        // Gather emotion context
        let mood = EmotionEngine.shared.currentMood
        let moodTrend = EmotionEngine.shared.profile.currentMoodTrend

        // Gather memory context
        let memories = ConversationMemoryService.shared.getRecentMoments(limit: 10)
        let weakAreas = ProactiveEngine.shared.analyzeWeakAreas()

        return AIService.shared.companionSystemPrompt(
            childName: profile.childName,
            subjects: profile.subjects,
            goals: profile.goals,
            stage: profile.stage,
            daysSinceJoin: profile.daysSinceJoin,
            stats: stats,
            examDaysLeft: profile.examDate.flatMap {
                Calendar.current.dateComponents([.day], from: Date(), to: $0).day
            },
            mood: mood,
            moodTrend: moodTrend,
            memories: memories,
            weakAreas: weakAreas
        )
    }
}
