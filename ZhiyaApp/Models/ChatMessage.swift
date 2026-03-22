import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    var content: String
    let timestamp: TimeInterval
    var isStreaming: Bool
    var messageType: MessageType
    var challengeData: ChallengeData?
    var suggestionData: SuggestionData?
    var studyPlanData: StudyPlanData?
    var imageData: Data?

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: TimeInterval = Date().timeIntervalSince1970, isStreaming: Bool = false, messageType: MessageType = .text, challengeData: ChallengeData? = nil, suggestionData: SuggestionData? = nil, studyPlanData: StudyPlanData? = nil, imageData: Data? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.messageType = messageType
        self.challengeData = challengeData
        self.suggestionData = suggestionData
        self.studyPlanData = studyPlanData
        self.imageData = imageData
    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

enum MessageType: String, Codable {
    case text
    case challengeCard
    case imageAnalysis
    case growthSnapshot
    case weeklyLetter
    case celebration
    case suggestion
    case studyPlan
}

struct ChallengeData: Codable {
    let questionId: String
    let paperId: String
    let chapterId: String
    let kpId: String
    let kpTitle: String
    let stem: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let difficulty: Int
    var selectedIndex: Int?
    var answered: Bool
    var isCorrect: Bool?

    init(from question: Question, paperId: String, chapterId: String, kpId: String, kpTitle: String) {
        self.questionId = question.id
        self.paperId = paperId
        self.chapterId = chapterId
        self.kpId = kpId
        self.kpTitle = kpTitle
        self.stem = question.stem
        self.options = question.options
        self.correctIndex = question.correctIndex
        self.explanation = question.explanation
        self.difficulty = question.difficulty
        self.selectedIndex = nil
        self.answered = false
        self.isCorrect = nil
    }

    /// Init from raw Synapse data (tool_result from zhiya_get_questions)
    init(questionId: String, paperId: String, chapterId: String, kpId: String, kpTitle: String,
         stem: String, options: [String], correctIndex: Int, explanation: String, difficulty: Int) {
        self.questionId = questionId
        self.paperId = paperId
        self.chapterId = chapterId
        self.kpId = kpId
        self.kpTitle = kpTitle
        self.stem = stem
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.difficulty = difficulty
        self.selectedIndex = nil
        self.answered = false
        self.isCorrect = nil
    }
}

struct SuggestionData: Codable {
    let text: String
    let action: SuggestionAction
    var tapped: Bool

    init(text: String, action: SuggestionAction, tapped: Bool = false) {
        self.text = text
        self.action = action
        self.tapped = tapped
    }
}

enum SuggestionAction: String, Codable {
    case startReview
    case startChallenge
    case viewGarden
    case dismiss
}

struct StudyPlanData: Codable {
    let title: String
    let items: [StudyPlanItem]
    var expanded: Bool

    init(title: String, items: [StudyPlanItem], expanded: Bool = false) {
        self.title = title
        self.items = items
        self.expanded = expanded
    }
}

struct StudyPlanItem: Codable, Identifiable {
    let id: String
    let day: String
    let topic: String
    var completed: Bool

    init(id: String = UUID().uuidString, day: String, topic: String, completed: Bool = false) {
        self.id = id
        self.day = day
        self.topic = topic
        self.completed = completed
    }
}
