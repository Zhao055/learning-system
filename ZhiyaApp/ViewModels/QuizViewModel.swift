import SwiftUI

/// Simplified QuizViewModel - now primarily manages ChallengeCard state within conversation
final class QuizViewModel: ObservableObject {
    @Published var state = QuizState()

    let paperId: String
    let chapterId: String
    let kpId: String
    let kpTitle: String

    init(paperId: String, chapterId: String, kpId: String, kpTitle: String) {
        self.paperId = paperId
        self.chapterId = chapterId
        self.kpId = kpId
        self.kpTitle = kpTitle
        loadQuestions()
    }

    private func loadQuestions() {
        state.questions = QuestionRepository.shared.getQuestions(paperId, chapterId: chapterId, kpId: kpId)
    }

    func selectOption(_ index: Int) {
        guard state.phase == .answering else { return }
        state.selectedIndex = index
    }

    func confirmAnswer() {
        guard let selected = state.selectedIndex,
              let question = state.currentQuestion else { return }

        let isCorrect = selected == question.correctIndex
        let answer = QuizAnswer(questionId: question.id, selectedIndex: selected, isCorrect: isCorrect)
        state.answers.append(answer)
        state.phase = .showingResult

        if isCorrect {
            state.consecutiveWrong = 0
        } else {
            state.consecutiveWrong += 1
        }

        ProgressService.shared.recordAnswer(
            paperId: paperId, chapterId: chapterId, kpId: kpId,
            questionId: question.id, correct: isCorrect, selectedIndex: selected
        )

        EmotionEngine.shared.updateFromQuizResult(correct: isCorrect, consecutiveWrong: state.consecutiveWrong)

        let stats = ProgressService.shared.getTotalStats()
        MemoryService.shared.checkMilestones(stats: stats, paperId: paperId, chapterId: chapterId)

        let kpProgress = ProgressService.shared.getKpProgress(paperId: paperId, chapterId: chapterId, kpId: kpId)
        let masteryRate = kpProgress.attempted > 0 ? Double(kpProgress.correct) / Double(kpProgress.attempted) : 0
        MemoryService.shared.updateTreeForProgress(dimension: .academic, kpId: kpId, kpTitle: kpTitle, masteryRate: masteryRate)
    }

    func nextQuestion() {
        if state.isLastQuestion {
            state.phase = .completed
        } else {
            state.currentIndex += 1
            state.selectedIndex = nil
            state.phase = .answering
        }
    }

    var quizResult: QuizResult? {
        guard state.phase == .completed else { return nil }
        let paperName = SubjectData.getPaper(paperId)?.name ?? paperId
        let chapterTitle = QuestionRepository.shared.getChapter(paperId, chapterId: chapterId)?.titleCn ?? chapterId
        return QuizResult(
            paperId: paperId, paperName: paperName,
            chapterId: chapterId, chapterTitle: chapterTitle,
            knowledgePointId: kpId, knowledgePointTitle: kpTitle,
            totalQuestions: state.questions.count, correctCount: state.correctCount,
            answers: state.answers, timestamp: Date().timeIntervalSince1970
        )
    }
}
