import Foundation

enum QuizPhase {
    case answering
    case showingResult
    case completed
}

struct QuizState {
    var questions: [Question] = []
    var currentIndex: Int = 0
    var selectedIndex: Int? = nil
    var answers: [QuizAnswer] = []
    var phase: QuizPhase = .answering
    var consecutiveWrong: Int = 0

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var correctCount: Int {
        answers.filter(\.isCorrect).count
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }
}
