import Foundation

struct ProgressRecord: Codable, Identifiable {
    var id: String { "\(paperId)_\(questionId)_\(Int(timestamp))" }
    let paperId: String
    let chapterId: String
    let kpId: String
    let questionId: String
    let correct: Bool
    let selectedIndex: Int
    let timestamp: TimeInterval
}

struct QuizAnswer: Codable {
    let questionId: String
    let selectedIndex: Int
    let isCorrect: Bool
}

struct QuizResult: Codable {
    let paperId: String
    let paperName: String
    let chapterId: String
    let chapterTitle: String
    let knowledgePointId: String
    let knowledgePointTitle: String
    let totalQuestions: Int
    let correctCount: Int
    let answers: [QuizAnswer]
    let timestamp: TimeInterval
}

struct KpProgress {
    let total: Int
    let correct: Int
    let attempted: Int
}

struct ChapterProgress {
    let totalKps: Int
    let completedKps: Int
    let correctRate: Double
}

struct PaperProgress {
    let totalChapters: Int
    let completedChapters: Int
    let correctRate: Double
}

struct TotalStats {
    let totalAnswered: Int
    let totalCorrect: Int
    let accuracy: Double
    let wrongCount: Int
}

struct WrongAnswerItem: Identifiable {
    var id: String { record.questionId }
    let record: ProgressRecord
    let question: Question
    let chapterTitle: String
    let kpTitle: String
    let paperName: String
}
