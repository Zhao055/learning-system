import Foundation

struct GrowthMemory: Identifiable, Codable {
    let id: String
    let type: MemoryType
    let title: String
    let content: String
    let timestamp: Date
    let dimension: GrowthDimensionType?
    let emotionalWeight: Double // 0-1, how emotionally significant

    init(id: String = UUID().uuidString, type: MemoryType, title: String, content: String, timestamp: Date = Date(), dimension: GrowthDimensionType? = nil, emotionalWeight: Double = 0.5) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.dimension = dimension
        self.emotionalWeight = emotionalWeight
    }
}

enum MemoryType: String, Codable {
    case academicBreakthrough  // 学业突破
    case emotionalMoment       // 情感时刻
    case lifeDiscovery         // 人生发现
    case milestone             // 里程碑
    case dream                 // 梦想
    case struggle              // 困难时刻
    case sharedJoy             // 共同喜悦
}

struct Milestone: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let achievedDate: Date
    let type: MilestoneType
    let celebrationShown: Bool

    init(id: String = UUID().uuidString, title: String, description: String, achievedDate: Date = Date(), type: MilestoneType, celebrationShown: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.achievedDate = achievedDate
        self.type = type
        self.celebrationShown = celebrationShown
    }
}

enum MilestoneType: String, Codable {
    case chapterComplete
    case perfectScore
    case firstQuestion
    case streakWeek
    case subjectMastery
    case emotionalGrowth
}

struct WeeklyLetter: Identifiable, Codable {
    let id: String
    let weekStart: Date
    let weekEnd: Date
    let topicsStudied: [String]
    let observation: String
    let suggestion: String
    let closing: String
    let generatedDate: Date

    init(id: String = UUID().uuidString, weekStart: Date, weekEnd: Date, topicsStudied: [String], observation: String, suggestion: String, closing: String, generatedDate: Date = Date()) {
        self.id = id
        self.weekStart = weekStart
        self.weekEnd = weekEnd
        self.topicsStudied = topicsStudied
        self.observation = observation
        self.suggestion = suggestion
        self.closing = closing
        self.generatedDate = generatedDate
    }
}
