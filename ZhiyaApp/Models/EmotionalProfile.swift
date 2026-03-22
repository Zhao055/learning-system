import Foundation

struct EmotionalProfile: Codable {
    var moodBaseline: DetectedMood = .neutral
    var anxietyTriggers: [String] = []
    var effectiveEncouragements: [String] = []
    var recoveryPattern: RecoveryPattern = .needsSpace
    var peakHours: [Int] = []     // hours of day when most productive
    var lowHours: [Int] = []      // hours when energy dips
    var recentMoods: [MoodEntry] = []

    var currentMoodTrend: MoodTrend {
        guard recentMoods.count >= 3 else { return .stable }
        let recent = recentMoods.suffix(5)
        let scores = recent.map(\.score)
        let avg = scores.reduce(0, +) / Double(scores.count)
        if avg > 0.6 { return .positive }
        if avg < 0.3 { return .declining }
        return .stable
    }
}

struct MoodEntry: Codable, Identifiable {
    let id: String
    let mood: DetectedMood
    let score: Double  // 0-1
    let context: String
    let timestamp: Date

    init(id: String = UUID().uuidString, mood: DetectedMood, score: Double, context: String = "", timestamp: Date = Date()) {
        self.id = id
        self.mood = mood
        self.score = score
        self.context = context
        self.timestamp = timestamp
    }
}

enum RecoveryPattern: String, Codable {
    case needsSpace      // 需要空间
    case needsCompany    // 需要陪伴
    case needsRedirection // 需要转移注意力
}

enum MoodTrend: String {
    case positive
    case stable
    case declining
}
