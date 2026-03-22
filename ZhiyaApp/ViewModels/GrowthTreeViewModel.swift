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
}
