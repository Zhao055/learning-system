import SwiftUI

/// Manages challenge card lifecycle: surface → answer → SM-2 → growth tree → milestone → follow-up.
@MainActor
final class ChallengeCoordinator: ObservableObject {
    @Published var showCelebration: Bool = false
    @Published var currentMilestone: Milestone?

    private var consecutiveWrongCount: Int = 0

    // MARK: - Surface Challenge

    func surfaceChallenge(profile: CompanionProfile, chatCoordinator: ChatCoordinator) {
        let service = QuestionSurfacingService.shared
        guard let (question, paperId, chapterId, kpId, kpTitle) = service.getNextQuestion(profile: profile) else {
            chatCoordinator.appendAssistantMessage("暂时没有合适的题目。继续聊天吧！", type: .text)
            return
        }

        let challengeData = ChallengeData(
            from: question, paperId: paperId, chapterId: chapterId, kpId: kpId, kpTitle: kpTitle
        )

        let message = ChatMessage(
            role: .assistant,
            content: "来试试这道题：",
            messageType: .challengeCard,
            challengeData: challengeData
        )
        chatCoordinator.messages.append(message)
        chatCoordinator.saveMessages()
    }

    // MARK: - Handle Answer

    func handleChallengeAnswer(messageId: String, selectedIndex: Int, chatCoordinator: ChatCoordinator, companionEngine: CompanionEngine) {
        guard let idx = chatCoordinator.messages.firstIndex(where: { $0.id == messageId }),
              var challenge = chatCoordinator.messages[idx].challengeData,
              !challenge.answered else { return }

        challenge.selectedIndex = selectedIndex
        challenge.answered = true
        challenge.isCorrect = selectedIndex == challenge.correctIndex
        chatCoordinator.messages[idx].challengeData = challenge

        // Record progress
        ProgressService.shared.recordAnswer(
            paperId: challenge.paperId,
            chapterId: challenge.chapterId,
            kpId: challenge.kpId,
            questionId: challenge.questionId,
            correct: challenge.isCorrect ?? false,
            selectedIndex: selectedIndex
        )

        // Update SM-2 spaced repetition
        let quality = QuestionSurfacingService.shared.qualityFromAccuracy(correct: challenge.isCorrect ?? false)
        QuestionSurfacingService.shared.updateSM2(
            kpId: challenge.kpId, quality: quality,
            paperId: challenge.paperId, chapterId: challenge.chapterId
        )

        // Track consecutive wrong
        if challenge.isCorrect == true {
            consecutiveWrongCount = 0
        } else {
            consecutiveWrongCount += 1
        }

        // Update emotion
        EmotionEngine.shared.updateFromQuizResult(correct: challenge.isCorrect ?? false, consecutiveWrong: consecutiveWrongCount)
        companionEngine.onConsecutiveWrong(consecutiveWrongCount)

        // Update growth tree
        let kpProgress = ProgressService.shared.getKpProgress(
            paperId: challenge.paperId, chapterId: challenge.chapterId, kpId: challenge.kpId
        )
        let masteryRate = kpProgress.attempted > 0 ? Double(kpProgress.correct) / Double(kpProgress.attempted) : 0
        let oldLeafCount = MemoryService.shared.growthTree.leaves.count
        MemoryService.shared.updateTreeForProgress(
            dimension: .academic, kpId: challenge.kpId, kpTitle: challenge.kpTitle, masteryRate: masteryRate
        )

        if MemoryService.shared.growthTree.leaves.count > oldLeafCount {
            chatCoordinator.appendAssistantMessage("\(challenge.kpTitle) 掌握度提升了！", type: .growthSnapshot)
        }

        // Check milestones
        let stats = ProgressService.shared.getTotalStats()
        let oldMilestoneCount = MemoryService.shared.milestones.count
        MemoryService.shared.checkMilestones(stats: stats, paperId: challenge.paperId, chapterId: challenge.chapterId)
        if MemoryService.shared.milestones.count > oldMilestoneCount {
            currentMilestone = MemoryService.shared.milestones.last
            showCelebration = true
            if let milestone = currentMilestone {
                chatCoordinator.appendAssistantMessage("🎉 \(milestone.title) — \(milestone.description)", type: .celebration)
            }
        }

        // Follow-up response
        if challenge.isCorrect == true {
            chatCoordinator.appendAssistantMessage("答对了！\(challenge.kpTitle) 掌握得不错。", type: .text)
        } else if consecutiveWrongCount >= 3 {
            chatCoordinator.appendAssistantMessage("连着几道都有点难，没关系。我们不着急。", type: .text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                chatCoordinator.appendAssistantMessage("想怎么继续？", type: .suggestion,
                    suggestionData: SuggestionData(text: "降低难度，来道简单的", action: .startChallenge))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                chatCoordinator.appendAssistantMessage("", type: .suggestion,
                    suggestionData: SuggestionData(text: "换个知识点", action: .startChallenge))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                chatCoordinator.appendAssistantMessage("或者不做题了，聊聊天也行", type: .suggestion,
                    suggestionData: SuggestionData(text: "聊聊天", action: .dismiss))
            }
        } else {
            let selectedLetter = ["A", "B", "C", "D"][selectedIndex]
            chatCoordinator.appendAssistantMessage("你选了\(selectedLetter)，你是怎么想的？来聊聊你的思路。", type: .text)
        }

        chatCoordinator.saveMessages()
    }

    enum SuggestionAction {
        case none
        case showGarden
    }

    // MARK: - Handle Suggestion Tap

    @discardableResult
    func handleSuggestionTap(messageId: String, chatCoordinator: ChatCoordinator, companionEngine: CompanionEngine) -> SuggestionAction {
        guard let idx = chatCoordinator.messages.firstIndex(where: { $0.id == messageId }),
              var suggestion = chatCoordinator.messages[idx].suggestionData,
              !suggestion.tapped else { return .none }

        suggestion.tapped = true
        chatCoordinator.messages[idx].suggestionData = suggestion

        switch suggestion.action {
        case .startReview:
            StudyPlanService.shared.generateStudyPlan(
                profile: companionEngine.profile,
                chatCoordinator: chatCoordinator
            )
            return .none
        case .startChallenge:
            surfaceChallenge(profile: companionEngine.profile, chatCoordinator: chatCoordinator)
            return .none
        case .viewGarden:
            return .showGarden
        case .dismiss:
            return .none
        }
    }
}
