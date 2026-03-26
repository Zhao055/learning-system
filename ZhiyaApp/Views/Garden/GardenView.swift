import SwiftUI

/// Growth garden — rewritten with GeometryReader relative positioning.
/// No hardcoded coordinates; all positions are proportional to screen size.
struct GardenView: View {
    @StateObject private var treeVM = GrowthTreeViewModel()
    @State private var selectedLeaf: TreeLeaf?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Dark garden background
                LinearGradient(
                    colors: [Color(hex: "1A3B2A"), Color(hex: "0D2818"), Color(hex: "0A1F14")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Stars (random but seeded)
                ForEach(0..<30, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(starOpacity(i)))
                        .frame(width: starSize(i))
                        .position(
                            x: w * starX(i),
                            y: h * starY(i)
                        )
                }

                // Ground
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "2D5A3D"), Color(hex: "1A3B2A").opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.6
                        )
                    )
                    .frame(width: w * 1.2, height: h * 0.3)
                    .position(x: w * 0.5, y: h * 0.75)

                // Growth Tree (centered)
                GardenTreeView(tree: treeVM.tree, width: w)
                    .position(x: w * 0.5, y: h * 0.45)

                // Leaf nodes around canopy
                ForEach(Array(treeVM.tree.leaves.prefix(12).enumerated()), id: \.element.id) { index, leaf in
                    LeafNodeView(leaf: leaf) {
                        selectedLeaf = leaf
                    }
                    .position(
                        x: w * 0.5 + leafOffsetX(index: index, radius: w * 0.25),
                        y: h * 0.35 + leafOffsetY(index: index, radius: h * 0.15)
                    )
                }

                // Header
                VStack {
                    HStack {
                        Text("成长花园")
                            .font(ZhiyaTheme.title(20))
                            .foregroundColor(.white)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("🌿 \(treeVM.tree.leaves.count) 片叶子")
                                .font(ZhiyaTheme.caption(13))
                                .foregroundColor(.white.opacity(0.8))
                            Text("📊 \(treeVM.treeStage)")
                                .font(ZhiyaTheme.caption(12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    // Four dimension progress bars
                    dimensionBars
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedLeaf) { leaf in
            LeafDetailSheet(leaf: leaf)
        }
        .onAppear { treeVM.load() }
    }

    // MARK: - Dimension Progress Bars

    private var dimensionBars: some View {
        HStack(spacing: 12) {
            ForEach(GrowthDimensionType.allCases, id: \.self) { dim in
                let branchLength = treeVM.tree.branches.first(where: { $0.dimension == dim })?.length ?? 0
                VStack(spacing: 4) {
                    Text(dim.icon)
                        .font(.system(size: 16))
                    GeometryReader { bar in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dim.color)
                                .frame(height: bar.size.height * CGFloat(branchLength))
                        }
                    }
                    .frame(width: 12, height: 50)
                    Text(dim.label)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
    }

    // MARK: - Deterministic star positions (avoid random on each render)

    private func starOpacity(_ i: Int) -> Double { [0.3, 0.5, 0.2, 0.6, 0.4][i % 5] }
    private func starSize(_ i: Int) -> CGFloat { [1.5, 2.0, 1.0, 2.5, 1.5][i % 5] }
    private func starX(_ i: Int) -> CGFloat { CGFloat((i * 37 + 13) % 100) / 100.0 }
    private func starY(_ i: Int) -> CGFloat { CGFloat((i * 23 + 7) % 40) / 100.0 }

    // MARK: - Leaf positions in a circle around canopy

    private func leafOffsetX(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / 12.0) - .pi / 2
        return radius * cos(angle)
    }

    private func leafOffsetY(index: Int, radius: CGFloat) -> CGFloat {
        let angle = Double(index) * (2 * .pi / 12.0) - .pi / 2
        return radius * sin(angle)
    }
}

// MARK: - Garden Tree (relative sizing)

private struct GardenTreeView: View {
    let tree: GrowthTree
    let width: CGFloat

    private var trunkHeight: CGFloat { width * 0.25 }
    private var trunkWidth: CGFloat { width * 0.06 }
    private var canopySize: CGFloat {
        switch tree.leaves.count {
        case 0...2: return width * 0.1
        case 3...5: return width * 0.15
        case 6...10: return width * 0.22
        case 11...30: return width * 0.3
        default: return width * 0.38
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Canopy
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ZhiyaTheme.canopyGreen, ZhiyaTheme.canopyGreen.opacity(0.6)],
                        center: .center,
                        startRadius: canopySize * 0.1,
                        endRadius: canopySize * 0.5
                    )
                )
                .frame(width: canopySize, height: canopySize)
                .shadow(color: ZhiyaTheme.canopyGreen.opacity(0.3), radius: 12)

            // Trunk
            RoundedRectangle(cornerRadius: trunkWidth * 0.3)
                .fill(
                    LinearGradient(
                        colors: [ZhiyaTheme.gardenTrunkLight, ZhiyaTheme.gardenTrunkDark],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: trunkWidth, height: trunkHeight)
        }
    }
}

// MARK: - Leaf Node

private struct LeafNodeView: View {
    let leaf: TreeLeaf
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundColor(ZhiyaTheme.leafGreen)
                Text(leaf.title.prefix(4) + "…")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Leaf Detail Sheet

private struct LeafDetailSheet: View {
    let leaf: TreeLeaf

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundColor(ZhiyaTheme.leafGreen)

            Text(leaf.title)
                .font(ZhiyaTheme.heading())
                .foregroundColor(ZhiyaTheme.darkBrown)

            Text("状态: \(leaf.growth.rawValue)")
                .font(ZhiyaTheme.body())
                .foregroundColor(ZhiyaTheme.lightBrown)

            ProgressView(value: leaf.growth == .full ? 1.0 : leaf.growth == .half ? 0.5 : 0.2)
                .tint(ZhiyaTheme.leafGreen)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 32)
        .presentationDetents([.medium])
    }
}
