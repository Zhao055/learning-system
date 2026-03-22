import Foundation

final class ProgressService: ObservableObject {
    static let shared = ProgressService()

    @Published private(set) var records: [ProgressRecord] = []

    private let key = "zhiya_progress_records"

    private init() {
        loadRecords()
    }

    // MARK: - Record

    func recordAnswer(paperId: String, chapterId: String, kpId: String, questionId: String, correct: Bool, selectedIndex: Int) {
        let record = ProgressRecord(
            paperId: paperId, chapterId: chapterId, kpId: kpId,
            questionId: questionId, correct: correct, selectedIndex: selectedIndex,
            timestamp: Date().timeIntervalSince1970
        )
        records.append(record)
        saveRecords()
    }

    // MARK: - Query

    func getKpProgress(paperId: String, chapterId: String, kpId: String) -> KpProgress {
        let kpRecords = records.filter { $0.paperId == paperId && $0.chapterId == chapterId && $0.kpId == kpId }
        let uniqueQuestions = Set(kpRecords.map(\.questionId))
        let correctQuestions = Set(kpRecords.filter(\.correct).map(\.questionId))
        let questions = QuestionRepository.shared.getQuestions(paperId, chapterId: chapterId, kpId: kpId)
        return KpProgress(total: questions.count, correct: correctQuestions.count, attempted: uniqueQuestions.count)
    }

    func getChapterProgress(paperId: String, chapterId: String) -> ChapterProgress {
        guard let chapter = QuestionRepository.shared.getChapter(paperId, chapterId: chapterId) else {
            return ChapterProgress(totalKps: 0, completedKps: 0, correctRate: 0)
        }
        let kps = chapter.knowledgePoints
        var completedKps = 0
        var totalCorrect = 0, totalAttempted = 0

        for kp in kps {
            let progress = getKpProgress(paperId: paperId, chapterId: chapterId, kpId: kp.id)
            let mastery = progress.attempted > 0 ? Double(progress.correct) / Double(progress.attempted) : 0
            if progress.attempted >= 3 && mastery >= 0.7 { completedKps += 1 }
            totalCorrect += progress.correct
            totalAttempted += progress.attempted
        }

        let rate = totalAttempted > 0 ? Double(totalCorrect) / Double(totalAttempted) : 0
        return ChapterProgress(totalKps: kps.count, completedKps: completedKps, correctRate: rate)
    }

    func getTotalStats() -> TotalStats {
        let total = records.count
        let correct = records.filter(\.correct).count
        // Count wrong based on most recent attempt per question
        var latestAttempt: [String: ProgressRecord] = [:]
        for record in records {
            if let existing = latestAttempt[record.questionId] {
                if record.timestamp > existing.timestamp {
                    latestAttempt[record.questionId] = record
                }
            } else {
                latestAttempt[record.questionId] = record
            }
        }
        let wrongCount = latestAttempt.values.filter { !$0.correct }.count
        return TotalStats(
            totalAnswered: total,
            totalCorrect: correct,
            accuracy: total > 0 ? Double(correct) / Double(total) : 0,
            wrongCount: wrongCount
        )
    }

    func getWrongAnswers(paperId: String? = nil) -> [WrongAnswerItem] {
        // Use most recent attempt per question to determine if it's still wrong
        var latestAttempt: [String: ProgressRecord] = [:]
        for record in records {
            if let existing = latestAttempt[record.questionId] {
                if record.timestamp > existing.timestamp {
                    latestAttempt[record.questionId] = record
                }
            } else {
                latestAttempt[record.questionId] = record
            }
        }

        var items: [WrongAnswerItem] = []
        for (_, record) in latestAttempt {
            // Only include if the most recent attempt was wrong
            guard !record.correct else { continue }
            if let filter = paperId, record.paperId != filter { continue }

            if let found = QuestionRepository.shared.findQuestion(questionId: record.questionId, paperId: record.paperId) {
                let paperName = SubjectData.getPaper(record.paperId)?.name ?? record.paperId
                items.append(WrongAnswerItem(record: record, question: found.question, chapterTitle: found.chapter.titleCn, kpTitle: found.kp.titleCn, paperName: paperName))
            }
        }
        // Sort by most recent wrong first
        return items.sorted { $0.record.timestamp > $1.record.timestamp }
    }

    func deleteWrongAnswer(questionId: String) {
        records.removeAll { $0.questionId == questionId && !$0.correct }
        saveRecords()
    }

    func clearAll() {
        records = []
        saveRecords()
    }

    // MARK: - Persistence

    private func loadRecords() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ProgressRecord].self, from: data) else { return }
        records = decoded
    }

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
