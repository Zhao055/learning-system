import Foundation

final class QuestionRepository {
    static let shared = QuestionRepository()
    private var cache: [String: QuestionBank] = [:]

    private init() {}

    func loadPaper(_ paperId: String) -> QuestionBank? {
        if let cached = cache[paperId] { return cached }

        guard let paper = SubjectData.getPaper(paperId),
              let url = Bundle.main.url(forResource: paper.jsonFile.replacingOccurrences(of: ".json", with: ""), withExtension: "json", subdirectory: "QuestionBanks"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(QuestionBank.self, from: data) else {
            return nil
        }

        cache[paperId] = bank
        return bank
    }

    func getChapters(_ paperId: String) -> [Chapter] {
        loadPaper(paperId)?.chapters ?? []
    }

    func getChapter(_ paperId: String, chapterId: String) -> Chapter? {
        getChapters(paperId).first { $0.id == chapterId }
    }

    func getKnowledgePoint(_ paperId: String, chapterId: String, kpId: String) -> KnowledgePoint? {
        getChapter(paperId, chapterId: chapterId)?.knowledgePoints.first { $0.id == kpId }
    }

    func getQuestions(_ paperId: String, chapterId: String, kpId: String) -> [Question] {
        getKnowledgePoint(paperId, chapterId: chapterId, kpId: kpId)?.questions ?? []
    }

    func findQuestion(questionId: String, paperId: String) -> (question: Question, chapter: Chapter, kp: KnowledgePoint)? {
        guard let bank = loadPaper(paperId) else { return nil }
        for chapter in bank.chapters {
            for kp in chapter.knowledgePoints {
                if let q = kp.questions.first(where: { $0.id == questionId }) {
                    return (q, chapter, kp)
                }
            }
        }
        return nil
    }
}
