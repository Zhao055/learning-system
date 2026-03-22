import Foundation

final class MemoryService: ObservableObject {
    static let shared = MemoryService()

    @Published private(set) var memories: [GrowthMemory] = []
    @Published private(set) var milestones: [Milestone] = []
    @Published private(set) var weeklyLetters: [WeeklyLetter] = []
    @Published private(set) var growthTree: GrowthTree = .initial

    private let memoriesKey = "zhiya_memories"
    private let milestonesKey = "zhiya_milestones"
    private let lettersKey = "zhiya_letters"
    private let treeKey = "zhiya_growth_tree"

    private init() {
        loadAll()
    }

    // MARK: - Memories

    func addMemory(_ memory: GrowthMemory) {
        memories.append(memory)
        save(memories, key: memoriesKey)
    }

    func getMemories(type: MemoryType? = nil, dimension: GrowthDimensionType? = nil) -> [GrowthMemory] {
        memories.filter { m in
            (type == nil || m.type == type) && (dimension == nil || m.dimension == dimension)
        }.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Milestones

    func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
        save(milestones, key: milestonesKey)

        // Add flower to tree
        let flower = TreeFlower(id: UUID().uuidString, milestoneId: milestone.id, title: milestone.title, bloomDate: milestone.achievedDate)
        growthTree.flowers.append(flower)
        save(growthTree, key: treeKey)
    }

    func checkMilestones(stats: TotalStats, paperId: String, chapterId: String?) {
        // First question
        if stats.totalAnswered == 1 && !milestones.contains(where: { $0.type == .firstQuestion }) {
            addMilestone(Milestone(title: "第一步", description: "完成了第一道题目", type: .firstQuestion))
        }

        // Perfect score on KP
        if let chapterId = chapterId {
            let chapters = QuestionRepository.shared.getChapters(paperId)
            for chapter in chapters where chapter.id == chapterId {
                let progress = ProgressService.shared.getChapterProgress(paperId: paperId, chapterId: chapterId)
                if progress.completedKps == progress.totalKps && progress.totalKps > 0 &&
                    !milestones.contains(where: { $0.type == .chapterComplete && $0.description.contains(chapter.titleCn) }) {
                    addMilestone(Milestone(
                        title: "章节通关", description: "完成了「\(chapter.titleCn)」的全部知识点",
                        type: .chapterComplete
                    ))
                }
            }
        }
    }

    // MARK: - Weekly Letter

    func addWeeklyLetter(_ letter: WeeklyLetter) {
        weeklyLetters.append(letter)
        save(weeklyLetters, key: lettersKey)
    }

    func latestLetter() -> WeeklyLetter? {
        weeklyLetters.sorted { $0.generatedDate > $1.generatedDate }.first
    }

    // MARK: - Growth Tree

    func updateTreeForProgress(dimension: GrowthDimensionType, kpId: String, kpTitle: String, masteryRate: Double) {
        // Update branch length
        if let idx = growthTree.branches.firstIndex(where: { $0.dimension == dimension }) {
            growthTree.branches[idx].length = min(1.0, growthTree.branches[idx].length + 0.02)
        }

        // Update or add leaf
        if let leafIdx = growthTree.leaves.firstIndex(where: { $0.knowledgePointId == kpId }) {
            if masteryRate >= 0.9 {
                growthTree.leaves[leafIdx].growth = .full
            } else if masteryRate >= 0.5 {
                growthTree.leaves[leafIdx].growth = .half
            }
        } else {
            let growth: LeafGrowth = masteryRate >= 0.9 ? .full : masteryRate >= 0.5 ? .half : .sprout
            growthTree.leaves.append(TreeLeaf(knowledgePointId: kpId, title: kpTitle, growth: growth))

            if let idx = growthTree.branches.firstIndex(where: { $0.dimension == dimension }) {
                growthTree.branches[idx].leafCount += 1
            }
        }

        // Trunk grows with total leaves
        growthTree.trunkThickness = min(5.0, 1.0 + Double(growthTree.leaves.count) * 0.05)

        save(growthTree, key: treeKey)
    }

    // MARK: - Persistence

    private func loadAll() {
        memories = load(key: memoriesKey) ?? []
        milestones = load(key: milestonesKey) ?? []
        weeklyLetters = load(key: lettersKey) ?? []
        growthTree = load(key: treeKey) ?? .initial
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
