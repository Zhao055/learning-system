import Foundation

enum RelationshipStage: String, Codable {
    case seed = "seed"           // 1-7 days
    case familiar = "familiar"   // 8-30 days
    case understanding = "understanding" // 31-90 days
    case companion = "companion" // 90+ days

    var label: String {
        switch self {
        case .seed: return "初识"
        case .familiar: return "熟悉"
        case .understanding: return "了解"
        case .companion: return "同行"
        }
    }

    static func from(daysSinceJoin: Int) -> RelationshipStage {
        switch daysSinceJoin {
        case 0...7: return .seed
        case 8...30: return .familiar
        case 31...90: return .understanding
        default: return .companion
        }
    }
}

enum ZhiyaEmotion: String, Codable {
    case gazing     // 注视 — default idle
    case happy      // 开心 — correct answer, milestone
    case thinking   // 思考 — processing, guiding
    case caring     // 关切 — student struggling
    case sleeping   // 睡觉 — late night
    case excited    // 兴奋 — big milestone
    case calm       // 平静 — low energy companion

    var eyeSymbol: String {
        switch self {
        case .gazing: return "👀"
        case .happy: return "😊"
        case .thinking: return "🤔"
        case .caring: return "🥺"
        case .sleeping: return "😴"
        case .excited: return "🤩"
        case .calm: return "😌"
        }
    }
}

enum DetectedMood: String, Codable {
    case smooth      // 顺畅
    case frustrated  // 受挫
    case lowEnergy   // 低能量
    case anxious     // 焦虑
    case neutral     // 中性
}

struct CompanionProfile: Codable {
    var childName: String = ""
    var joinDate: Date = Date()
    var subjects: [String] = []
    var goals: String = ""
    var examDate: Date? = nil
    var treeLevel: Int = 1

    var daysSinceJoin: Int {
        Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
    }

    var stage: RelationshipStage {
        .from(daysSinceJoin: daysSinceJoin)
    }
}
