import Foundation

final class QuestionSurfacingService {
    static let shared = QuestionSurfacingService()

    /// SM-2 scheduling data per knowledge point
    private struct SM2Data: Codable {
        var easeFactor: Double = 2.5  // EF starts at 2.5
        var interval: Int = 1          // days until next review
        var repetitions: Int = 0       // consecutive correct count
        var nextReview: TimeInterval   // unix timestamp of next review
        var lastPaperId: String = ""
        var lastChapterId: String = ""
    }

    private let sm2Key = "zhiya_sm2_data"
    private var sm2Cache: [String: SM2Data] = [:]  // kpId -> SM2Data

    private init() {
        loadSM2Data()
    }

    /// Returns the next question to surface based on SM-2 spaced repetition.
    func getNextQuestion(profile: CompanionProfile) -> (Question, String, String, String, String)? {
        // Strategy 1: SM-2 due reviews (adaptive spacing)
        if let result = findSM2DueQuestion() {
            return result
        }

        // Strategy 2: Wrong answers that need retry
        if let result = findWrongAnswerQuestion() {
            return result
        }

        // Strategy 3: New questions from enrolled subjects
        if let result = findNewQuestion(subjects: profile.subjects) {
            return result
        }

        return nil
    }

    // MARK: - SM-2 Algorithm

    /// Update SM-2 data after answering a question for a KP.
    /// quality: 0-5 scale (0-1 = complete failure, 2 = barely recall, 3 = correct with effort, 4 = correct, 5 = easy)
    func updateSM2(kpId: String, quality: Int, paperId: String, chapterId: String) {
        var data = sm2Cache[kpId] ?? SM2Data(nextReview: Date().timeIntervalSince1970)
        let q = max(0, min(5, quality))

        if q >= 3 {
            // Correct response
            switch data.repetitions {
            case 0: data.interval = 1
            case 1: data.interval = 6
            default: data.interval = Int(Double(data.interval) * data.easeFactor)
            }
            data.repetitions += 1
        } else {
            // Incorrect — reset
            data.repetitions = 0
            data.interval = 1
        }

        // Update ease factor: EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
        data.easeFactor = data.easeFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        data.easeFactor = max(1.3, data.easeFactor) // minimum EF is 1.3

        data.nextReview = Date().timeIntervalSince1970 + Double(data.interval) * 24 * 3600
        data.lastPaperId = paperId
        data.lastChapterId = chapterId

        sm2Cache[kpId] = data
        saveSM2Data()
    }

    /// Convert answer accuracy to SM-2 quality (0-5)
    func qualityFromAccuracy(correct: Bool, responseTimeSeconds: Double? = nil) -> Int {
        if !correct { return 1 }
        // If answered quickly, higher quality
        if let time = responseTimeSeconds, time < 10 { return 5 }
        if let time = responseTimeSeconds, time < 30 { return 4 }
        return 3
    }

    // MARK: - SM-2 Due Questions

    private func findSM2DueQuestion() -> (Question, String, String, String, String)? {
        let now = Date().timeIntervalSince1970
        let records = ProgressService.shared.records

        // Find KPs that are due for review
        let dueKPs = sm2Cache.filter { $0.value.nextReview <= now }
            .sorted { $0.value.nextReview < $1.value.nextReview } // most overdue first

        for (kpId, data) in dueKPs {
            let paperId = data.lastPaperId
            let chapterId = data.lastChapterId
            guard !paperId.isEmpty else { continue }

            let questions = QuestionRepository.shared.getQuestions(paperId, chapterId: chapterId, kpId: kpId)
            let recentIds = Set(records.filter { $0.kpId == kpId }.suffix(5).map(\.questionId))
            let unrecentQuestions = questions.filter { !recentIds.contains($0.id) }

            if let q = unrecentQuestions.randomElement() ?? questions.randomElement() {
                let kpTitle = QuestionRepository.shared.getKnowledgePoint(paperId, chapterId: chapterId, kpId: kpId)?.titleCn ?? ""
                return (q, paperId, chapterId, kpId, kpTitle)
            }
        }

        // Fallback: also check KPs with records but no SM2 data (migration from old system)
        let kpIds = Set(sm2Cache.keys)
        var kpLastTime: [String: (TimeInterval, String, String)] = [:]
        for record in records {
            if !kpIds.contains(record.kpId) {
                if let existing = kpLastTime[record.kpId] {
                    if record.timestamp > existing.0 {
                        kpLastTime[record.kpId] = (record.timestamp, record.paperId, record.chapterId)
                    }
                } else {
                    kpLastTime[record.kpId] = (record.timestamp, record.paperId, record.chapterId)
                }
            }
        }

        // Initialize SM2 for untracked KPs that are >1 day old
        let oneDayAgo = now - 24 * 3600
        for (kpId, (lastTime, paperId, chapterId)) in kpLastTime where lastTime < oneDayAgo {
            sm2Cache[kpId] = SM2Data(
                easeFactor: 2.5, interval: 1, repetitions: 0,
                nextReview: lastTime + 24 * 3600,
                lastPaperId: paperId, lastChapterId: chapterId
            )
        }
        saveSM2Data()

        // Re-check with newly initialized data
        let newlyDue = kpLastTime.filter { $0.value.0 < oneDayAgo }
            .sorted { $0.value.0 < $1.value.0 }

        for (kpId, (_, paperId, chapterId)) in newlyDue {
            let questions = QuestionRepository.shared.getQuestions(paperId, chapterId: chapterId, kpId: kpId)
            let recentIds = Set(records.filter { $0.kpId == kpId }.suffix(5).map(\.questionId))
            let unrecentQuestions = questions.filter { !recentIds.contains($0.id) }
            if let q = unrecentQuestions.randomElement() ?? questions.randomElement() {
                let kpTitle = QuestionRepository.shared.getKnowledgePoint(paperId, chapterId: chapterId, kpId: kpId)?.titleCn ?? ""
                return (q, paperId, chapterId, kpId, kpTitle)
            }
        }

        return nil
    }

    /// Find a question related to a previously wrong answer
    private func findWrongAnswerQuestion() -> (Question, String, String, String, String)? {
        let wrongItems = ProgressService.shared.getWrongAnswers()
        guard let item = wrongItems.first else { return nil }

        let questions = QuestionRepository.shared.getQuestions(item.record.paperId, chapterId: item.record.chapterId, kpId: item.record.kpId)
        if let q = questions.first(where: { $0.id != item.record.questionId }) ?? questions.first {
            return (q, item.record.paperId, item.record.chapterId, item.record.kpId, item.kpTitle)
        }

        return nil
    }

    /// Find a new question from enrolled subjects
    private func findNewQuestion(subjects: [String]) -> (Question, String, String, String, String)? {
        let answeredIds = Set(ProgressService.shared.records.map(\.questionId))

        for subjectId in subjects {
            guard let subject = SubjectData.getSubject(subjectId) else { continue }
            for paper in subject.papers where paper.available {
                for chapter in QuestionRepository.shared.getChapters(paper.id) {
                    for kp in chapter.knowledgePoints {
                        if let q = kp.questions.first(where: { !answeredIds.contains($0.id) }) {
                            return (q, paper.id, chapter.id, kp.id, kp.titleCn)
                        }
                    }
                }
            }
        }

        // Fallback: random question
        for subjectId in subjects {
            guard let subject = SubjectData.getSubject(subjectId) else { continue }
            for paper in subject.papers where paper.available {
                for chapter in QuestionRepository.shared.getChapters(paper.id) {
                    for kp in chapter.knowledgePoints {
                        if let q = kp.questions.randomElement() {
                            return (q, paper.id, chapter.id, kp.id, kp.titleCn)
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Persistence

    private func loadSM2Data() {
        guard let data = UserDefaults.standard.data(forKey: sm2Key),
              let decoded = try? JSONDecoder().decode([String: SM2Data].self, from: data) else { return }
        sm2Cache = decoded
    }

    private func saveSM2Data() {
        if let data = try? JSONEncoder().encode(sm2Cache) {
            UserDefaults.standard.set(data, forKey: sm2Key)
        }
    }
}
