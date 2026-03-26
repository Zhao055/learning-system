import Foundation

/// Generates study plans from weak areas and progress data.
@MainActor
final class StudyPlanService {
    static let shared = StudyPlanService()
    private init() {}

    func generateStudyPlan(profile: CompanionProfile, chatCoordinator: ChatCoordinator) {
        let wrongAnswers = ProgressService.shared.getWrongAnswers()
        let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

        var planItems: [StudyPlanItem] = []
        var topicsSeen = Set<String>()

        // Priority: wrong answers first
        for (i, item) in wrongAnswers.prefix(5).enumerated() {
            let dayIndex = i % 7
            if !topicsSeen.contains(item.kpTitle) {
                planItems.append(StudyPlanItem(day: days[dayIndex], topic: "复习 \(item.kpTitle)"))
                topicsSeen.insert(item.kpTitle)
            }
        }

        // Fill remaining days with new material
        if planItems.count < 5 {
            for subjectId in profile.subjects {
                guard let subject = SubjectData.getSubject(subjectId) else { continue }
                for paper in subject.papers where paper.available {
                    for chapter in QuestionRepository.shared.getChapters(paper.id) {
                        for kp in chapter.knowledgePoints {
                            if !topicsSeen.contains(kp.titleCn) && planItems.count < 7 {
                                let dayIndex = planItems.count % 7
                                planItems.append(StudyPlanItem(day: days[dayIndex], topic: kp.titleCn))
                                topicsSeen.insert(kp.titleCn)
                            }
                        }
                    }
                }
            }
        }

        guard !planItems.isEmpty else {
            chatCoordinator.appendAssistantMessage("目前没有足够的数据生成计划。先做几道题，我就能帮你制定了！", type: .text)
            return
        }

        let planData = StudyPlanData(title: "本周复习计划", items: planItems)
        let message = ChatMessage(
            role: .assistant,
            content: "根据你的学习情况，我给你安排了这些：",
            messageType: .studyPlan,
            studyPlanData: planData
        )
        chatCoordinator.messages.append(message)
        chatCoordinator.saveMessages()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            chatCoordinator.appendAssistantMessage("先从第一个开始？", type: .suggestion,
                suggestionData: SuggestionData(text: "开始", action: .startChallenge))
        }
    }
}
