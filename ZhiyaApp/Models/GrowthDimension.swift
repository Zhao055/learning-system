import SwiftUI

enum GrowthDimensionType: String, Codable, CaseIterable {
    case academic       // 学科能力
    case metacognitive  // 元认知与习惯
    case emotional      // 情绪智识
    case lifeExploration // 人生探索

    var label: String {
        switch self {
        case .academic: return "学科能力"
        case .metacognitive: return "元认知"
        case .emotional: return "情绪智识"
        case .lifeExploration: return "人生探索"
        }
    }

    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .metacognitive: return "brain.head.profile"
        case .emotional: return "heart.fill"
        case .lifeExploration: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .academic: return ZhiyaTheme.wisdom
        case .metacognitive: return ZhiyaTheme.patience
        case .emotional: return ZhiyaTheme.empathy
        case .lifeExploration: return ZhiyaTheme.passion
        }
    }
}

struct GrowthSnapshot: Codable, Identifiable {
    let id: String
    let dimension: GrowthDimensionType
    let score: Double  // 0-100
    let date: Date
    let details: String

    init(id: String = UUID().uuidString, dimension: GrowthDimensionType, score: Double, date: Date = Date(), details: String = "") {
        self.id = id
        self.dimension = dimension
        self.score = score
        self.date = date
        self.details = details
    }
}

struct GrowthTree: Codable {
    var trunkThickness: Double = 1.0   // grows with time
    var branches: [TreeBranch] = []
    var leaves: [TreeLeaf] = []
    var flowers: [TreeFlower] = []
    var rings: Int = 0                  // years

    static var initial: GrowthTree {
        GrowthTree(
            branches: GrowthDimensionType.allCases.map { dim in
                TreeBranch(dimension: dim, length: 0.1, leafCount: 0)
            }
        )
    }
}

struct TreeBranch: Codable, Identifiable {
    var id: String { dimension.rawValue }
    let dimension: GrowthDimensionType
    var length: Double       // 0-1
    var leafCount: Int
}

struct TreeLeaf: Codable, Identifiable {
    let id: String
    let knowledgePointId: String
    let title: String
    var growth: LeafGrowth   // sprout -> half -> full

    init(id: String = UUID().uuidString, knowledgePointId: String, title: String, growth: LeafGrowth = .sprout) {
        self.id = id
        self.knowledgePointId = knowledgePointId
        self.title = title
        self.growth = growth
    }
}

enum LeafGrowth: String, Codable {
    case sprout   // 嫩芽
    case half     // 半展
    case full     // 完全展开
}

struct TreeFlower: Codable, Identifiable {
    let id: String
    let milestoneId: String
    let title: String
    let bloomDate: Date
}
