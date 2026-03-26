import SwiftUI

final class GrowthTreeViewModel: ObservableObject {
    @Published var tree: GrowthTree = .initial
    @Published var selectedBranch: GrowthDimensionType? = nil

    func load() {
        tree = MemoryService.shared.growthTree
    }

    var totalLeaves: Int {
        tree.leaves.count
    }

    var fullLeaves: Int {
        tree.leaves.filter { $0.growth == .full }.count
    }

    func leavesFor(dimension: GrowthDimensionType) -> [TreeLeaf] {
        // Filter leaves by branch - for now all are academic
        tree.leaves
    }

    var treeStage: String {
        switch tree.leaves.count {
        case 0...2: return "小芽"
        case 3...10: return "小植物"
        case 11...30: return "小树"
        default: return "大树"
        }
    }

    // MARK: - Growth Narrative

    struct GrowthStory: Identifiable {
        let id = UUID()
        let title: String
        let content: String
        let icon: String
    }

    var growthStories: [GrowthStory] {
        var stories: [GrowthStory] = []
        let stats = ProgressService.shared.getTotalStats()
        let memories = MemoryService.shared.getMemories()
        let moments = ConversationMemoryService.shared.getRecentMoments(limit: 50)

        // Journey overview
        if stats.totalAnswered > 0 {
            let fullCount = tree.leaves.filter { $0.growth == .full }.count
            stories.append(GrowthStory(
                title: "你的学习旅程",
                content: "从第一道题到现在，你已经掌握了\(tree.leaves.count)个知识点，其中\(fullCount)个完全掌握。一共做了\(stats.totalAnswered)道题。",
                icon: "leaf.fill"
            ))
        }

        // Breakthrough story
        let breakthroughs = moments.filter { $0.category == .breakthrough }
        if let latest = breakthroughs.first {
            stories.append(GrowthStory(
                title: "突破时刻",
                content: latest.content,
                icon: "sparkles"
            ))
        }

        // Dream story
        let dreams = moments.filter { $0.category == .dream }
        if let dream = dreams.first {
            stories.append(GrowthStory(
                title: "你的梦想",
                content: dream.content,
                icon: "star.fill"
            ))
        }

        // Perseverance story — find frustrations followed by breakthroughs
        let frustrations = moments.filter { $0.category == .frustration }
        if !frustrations.isEmpty && !breakthroughs.isEmpty {
            stories.append(GrowthStory(
                title: "坚持的力量",
                content: "你经历了\(frustrations.count)次困难时刻，但每一次都坚持下来了。这比答对更重要。",
                icon: "heart.fill"
            ))
        }

        // Milestone count
        let milestones = MemoryService.shared.milestones
        if !milestones.isEmpty {
            stories.append(GrowthStory(
                title: "里程碑",
                content: "你已经达成了\(milestones.count)个里程碑。每一个都是成长的印记。",
                icon: "flag.fill"
            ))
        }

        return stories
    }
}
