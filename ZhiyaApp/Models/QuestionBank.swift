import Foundation

struct QuestionBank: Codable {
    let chapters: [Chapter]
}

struct Chapter: Codable, Identifiable {
    let id: String
    let title: String
    let titleCn: String
    let knowledgePoints: [KnowledgePoint]
}

struct KnowledgePoint: Codable, Identifiable {
    let id: String
    let title: String
    let titleCn: String
    let image: String
    let questions: [Question]
}

struct Question: Codable, Identifiable {
    let id: String
    let stem: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let difficulty: Int
}
