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

        // 智慧品格：给出上下文，不是冷冰冰地出题
        let intro = contextualChallengeIntro(kpTitle: kpTitle, paperId: paperId, chapterId: chapterId, kpId: kpId)

        let message = ChatMessage(
            role: .assistant,
            content: intro,
            messageType: .challengeCard,
            challengeData: challengeData
        )
        chatCoordinator.messages.append(message)
        chatCoordinator.saveMessages()
    }

    /// 根据学生在该知识点的历史给出个性化的出题引导语
    private func contextualChallengeIntro(kpTitle: String, paperId: String, chapterId: String, kpId: String) -> String {
        let kpProgress = ProgressService.shared.getKpProgress(paperId: paperId, chapterId: chapterId, kpId: kpId)

        if kpProgress.attempted == 0 {
            return "来试试\(kpTitle)的第一道题，看看你的感觉："
        }

        let mastery = kpProgress.attempted > 0 ? Double(kpProgress.correct) / Double(kpProgress.attempted) : 0

        if mastery >= 0.8 {
            return "\(kpTitle)你之前做得不错，来道稍有挑战的："
        } else if mastery >= 0.5 {
            return "\(kpTitle)上次有些地方还不太确定，再来一道巩固一下？"
        } else {
            return "我们换个角度看看\(kpTitle)，试试这道："
        }
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

        // Follow-up response — 品格驱动反馈
        if challenge.isCorrect == true {
            // 正直品格：表扬要具体，不空洞
            let kpProgress = ProgressService.shared.getKpProgress(
                paperId: challenge.paperId, chapterId: challenge.chapterId, kpId: challenge.kpId
            )
            if kpProgress.attempted <= 1 {
                chatCoordinator.appendAssistantMessage("对了！你对\(challenge.kpTitle)的理解很准确。", type: .text)
            } else if consecutiveWrongCount == 0 {
                // 包容品格：记录相对于自己的进步
                chatCoordinator.appendAssistantMessage("又对了！上次这类题你还有点犹豫，现在很果断了。", type: .text)
            } else {
                // 热爱品格：庆祝真实的进步
                chatCoordinator.appendAssistantMessage("经过几次尝试后做对了，这才是真正的掌握。你在\(challenge.kpTitle)上有了真实的进步。", type: .text)
            }
        } else if consecutiveWrongCount >= 3 {
            // 体贴品格：先关心人再谈题
            chatCoordinator.appendAssistantMessage("连着几道都不太顺，我看到你一直在坚持。要不我们换个方式？", type: .text)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                chatCoordinator.appendAssistantMessage("想怎么继续？", type: .suggestion,
                    suggestionData: SuggestionData(text: "换个角度，聊聊这个知识点", action: .startChallenge))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                chatCoordinator.appendAssistantMessage("", type: .suggestion,
                    suggestionData: SuggestionData(text: "先做别的，晚点再回来", action: .startChallenge))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                chatCoordinator.appendAssistantMessage("不做题了也完全可以", type: .suggestion,
                    suggestionData: SuggestionData(text: "聊聊天", action: .dismiss))
            }
        } else {
            // 智慧品格：苏格拉底引导，不直接讲答案
            let selectedLetter = ["A", "B", "C", "D"][selectedIndex]
            let correctLetter = ["A", "B", "C", "D"][challenge.correctIndex]
            chatCoordinator.appendAssistantMessage("你选了\(selectedLetter)，正确答案是\(correctLetter)。你是怎么想的？我们一起看看你的思路哪里可以调整。", type: .text)
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
