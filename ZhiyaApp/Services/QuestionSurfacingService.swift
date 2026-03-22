import Foundation

final class QuestionSurfacingService {
    static let shared = QuestionSurfacingService()

    private init() {}

    /// Returns the next question to surface based on spaced repetition and profile context.
    /// Returns: (Question, paperId, chapterId, kpId, kpTitle)
    func getNextQuestion(profile: CompanionProfile) -> (Question, String, String, String, String)? {
        // Strategy 1: Review due KPs (spaced repetition)
        if let result = findDueReviewQuestion() {
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

    /// Find a question from a KP that hasn't been practiced recently
    private func findDueReviewQuestion() -> (Question, String, String, String, String)? {
        let records = ProgressService.shared.records
        let now = Date().timeIntervalSince1970
        let threeDays: TimeInterval = 3 * 24 * 3600

        // Group records by KP and find last practice time
        var kpLastTime: [String: (TimeInterval, String, String, String)] = [:]  // kpId -> (lastTime, paperId, chapterId, kpId)
        for record in records {
            let key = record.kpId
            if let existing = kpLastTime[key] {
                if record.timestamp > existing.0 {
                    kpLastTime[key] = (record.timestamp, record.paperId, record.chapterId, record.kpId)
                }
            } else {
                kpLastTime[key] = (record.timestamp, record.paperId, record.chapterId, record.kpId)
            }
        }

        // Find KPs due for review (>3 days since last practice)
        let dueKPs = kpLastTime.filter { now - $0.value.0 > threeDays }

        for (_, (_, paperId, chapterId, kpId)) in dueKPs.sorted(by: { $0.value.0 < $1.value.0 }) {
            let questions = QuestionRepository.shared.getQuestions(paperId, chapterId: chapterId, kpId: kpId)
            // Pick a question not recently answered
            let recentIds = Set(records.filter { $0.kpId == kpId }.suffix(5).map(\.questionId))
            if let q = questions.first(where: { !recentIds.contains($0.id) }) ?? questions.randomElement() {
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

        // Get a different question from the same KP
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

        // Fallback: any random question from any subject
        for subject in SubjectData.subjects {
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
}
