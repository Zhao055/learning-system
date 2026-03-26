import SwiftUI
import Combine

/// Slim orchestrator: holds UI state, delegates to coordinators.
@MainActor
final class CompanionViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var showGarden: Bool = false
    @Published var showSettings: Bool = false
    @Published var showCamera: Bool = false
    @Published var isRecording: Bool = false
    @Published var mascotCollapsed: Bool = false

    let chatCoordinator: ChatCoordinator
    let challengeCoordinator: ChallengeCoordinator
    let companionEngine: CompanionEngine
    private var cancellables = Set<AnyCancellable>()

    init(companionEngine: CompanionEngine) {
        self.companionEngine = companionEngine
        self.chatCoordinator = ChatCoordinator()
        self.challengeCoordinator = ChallengeCoordinator()

        // Forward chatCoordinator's objectWillChange so SwiftUI redraws
        chatCoordinator.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Proactive Messages

    func generateProactiveMessages() {
        if let last = chatCoordinator.messages.last, last.role == .assistant,
           Date().timeIntervalSince1970 - last.timestamp < 60 { return }

        // Check for Synapse proactive messages first
        let synapseMessages = NotificationService.shared.consumePendingMessages()
        for msg in synapseMessages {
            chatCoordinator.appendAssistantMessage(msg.body, type: msg.messageType)
        }

        // If no Synapse messages, use local proactive engine
        if synapseMessages.isEmpty {
            let lastTimestamp = chatCoordinator.messages.last?.timestamp
            let proactiveMessages = ProactiveEngine.shared.generateMessages(
                profile: companionEngine.profile,
                lastMessageTimestamp: lastTimestamp
            )
            for msg in proactiveMessages {
                chatCoordinator.appendAssistantMessage(msg.content, type: msg.messageType, suggestionData: msg.suggestionData)
            }
            WeeklyLetterService.shared.checkAndGenerateWeeklyLetter(
                profile: companionEngine.profile, chatCoordinator: chatCoordinator
            )
        }

        companionEngine.recordActivity()
    }

    // MARK: - Send Message

    func sendMessage() {
        let text = inputText
        inputText = ""

        if !mascotCollapsed {
            withAnimation(.easeOut(duration: 0.3)) { mascotCollapsed = true }
        }

        chatCoordinator.sendMessage(text, companionEngine: companionEngine)
    }

    // MARK: - Send Image

    func sendImage(_ imageData: Data) {
        if !mascotCollapsed {
            withAnimation(.easeOut(duration: 0.3)) { mascotCollapsed = true }
        }
        chatCoordinator.sendImage(imageData)
    }

    // MARK: - Challenge Answer

    func handleChallengeAnswer(messageId: String, selectedIndex: Int) {
        challengeCoordinator.handleChallengeAnswer(
            messageId: messageId,
            selectedIndex: selectedIndex,
            chatCoordinator: chatCoordinator,
            companionEngine: companionEngine
        )
    }

    // MARK: - Suggestion Tap

    func handleSuggestionTap(messageId: String) {
        let action = challengeCoordinator.handleSuggestionTap(
            messageId: messageId,
            chatCoordinator: chatCoordinator,
            companionEngine: companionEngine
        )
        if action == .showGarden {
            showGarden = true
        }
    }

    // MARK: - Surface Challenge

    func surfaceChallenge() {
        challengeCoordinator.surfaceChallenge(
            profile: companionEngine.profile,
            chatCoordinator: chatCoordinator
        )
    }
}
