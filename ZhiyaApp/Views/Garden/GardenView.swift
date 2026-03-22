import SwiftUI

struct GardenView: View {
    @StateObject private var treeVM = GrowthTreeViewModel()
    @State private var memories: [GrowthMemory] = []
    @State private var selectedMemory: GrowthMemory?
    @State private var fireflies: [Firefly] = []
    @State private var stones: [Stone] = []

    struct Firefly: Identifiable {
        let id = UUID()
        let memory: GrowthMemory
        var position: CGPoint
        var phase: Double
    }

    struct Stone: Identifiable {
        let id = UUID()
        let milestone: Milestone
        var position: CGPoint
    }

    var body: some View {
        ZStack {
            // Garden background
            LinearGradient(
                colors: [Color(hex: "1A3B2A"), Color(hex: "0D2818"), Color(hex: "0A1F14")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            GeometryReader { geo in
                ForEach(0..<30, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.4)
                        )
                }
            }

            // Main content
            GeometryReader { geo in
                ZStack {
                    // Ground
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "2D5A3D"), Color(hex: "1A3B2A").opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.6
                            )
                        )
                        .frame(width: geo.size.width * 1.2, height: geo.size.height * 0.3)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.75)

                    // Growth Tree
                    gardenTree
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.45)

                    // Fireflies (emotional memories)
                    ForEach(fireflies) { fly in
                        FireflyView(firefly: fly) {
                            selectedMemory = fly.memory
                        }
                    }

                    // Stones (milestones)
                    ForEach(stones) { stone in
                        StoneView(stone: stone) {
                            // Could show milestone detail
                        }
                    }
                }
            }

            // Header
            VStack {
                HStack {
                    // Swipe hint
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Text("花园")
                            .font(ZhiyaTheme.heading())
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Info
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(treeVM.treeStage)
                            .font(ZhiyaTheme.label(13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(treeVM.totalLeaves)片叶子 · \(treeVM.fullLeaves)片完全展开")
                            .font(ZhiyaTheme.caption(11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }

            // Memory popup
            if let memory = selectedMemory {
                memoryPopup(memory: memory)
            }
        }
        .onAppear {
            treeVM.load()
            memories = MemoryService.shared.getMemories()
            generateFireflies()
            generateStones()
        }
    }

    // MARK: - Garden Tree

    private var gardenTree: some View {
        let leafCount = treeVM.tree.leaves.count
        let treeSize: CGFloat = CGFloat(80 + leafCount * 3).clamped(to: 80...250)

        return VStack(spacing: 0) {
            // Canopy
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Ellipse()
                        .fill(Color(hex: "4A8B5C").opacity(0.5 + Double(i) * 0.15))
                        .frame(
                            width: treeSize - CGFloat(i) * 20,
                            height: treeSize * 0.65 - CGFloat(i) * 12
                        )
                        .offset(x: CGFloat(i - 1) * 12, y: CGFloat(i) * -8)
                }

                // Glow effect for leaves
                if leafCount > 5 {
                    Ellipse()
                        .fill(Color(hex: "7BC88F").opacity(0.15))
                        .frame(width: treeSize + 20, height: treeSize * 0.65 + 15)
                        .blur(radius: 10)
                }
            }

            // Trunk
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "5C4033"), Color(hex: "3E2723")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat(treeVM.tree.trunkThickness) * 6, height: 50)
        }
    }

    // MARK: - Fireflies & Stones

    private func generateFireflies() {
        let emotionalMemories = memories.filter { $0.type == .emotionalMoment || $0.type == .sharedJoy || $0.type == .dream }
        fireflies = emotionalMemories.prefix(15).enumerated().map { i, memory in
            Firefly(
                memory: memory,
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 200...600)
                ),
                phase: Double(i) * 0.5
            )
        }
    }

    private func generateStones() {
        let milestones = MemoryService.shared.milestones
        stones = milestones.prefix(10).enumerated().map { i, milestone in
            Stone(
                milestone: milestone,
                position: CGPoint(
                    x: CGFloat(80 + i * 30),
                    y: CGFloat.random(in: 550...650)
                )
            )
        }
    }

    // MARK: - Memory Popup

    private func memoryPopup(memory: GrowthMemory) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { selectedMemory = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Text(memory.title)
                    .font(ZhiyaTheme.heading(16))
                    .foregroundColor(.white)

                Text(memory.content)
                    .font(ZhiyaTheme.body(14))
                    .foregroundColor(.white.opacity(0.8))

                Text(memory.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(ZhiyaTheme.caption(11))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(Color.black.opacity(0.6))
            .cornerRadius(ZhiyaTheme.cornerRadius)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onTapGesture { withAnimation { selectedMemory = nil } }
    }
}

// MARK: - Firefly View

private struct FireflyView: View {
    let firefly: GardenView.Firefly
    let onTap: () -> Void

    @State private var glowing = false
    @State private var driftX: CGFloat = 0
    @State private var driftY: CGFloat = 0

    var body: some View {
        Circle()
            .fill(Color(hex: "FFEB3B").opacity(glowing ? 0.8 : 0.3))
            .frame(width: 8, height: 8)
            .shadow(color: Color(hex: "FFEB3B").opacity(0.5), radius: glowing ? 12 : 4)
            .position(
                x: firefly.position.x + driftX,
                y: firefly.position.y + driftY
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2 + firefly.phase).repeatForever(autoreverses: true)) {
                    glowing = true
                }
                withAnimation(.easeInOut(duration: 4 + firefly.phase).repeatForever(autoreverses: true)) {
                    driftX = CGFloat.random(in: -20...20)
                    driftY = CGFloat.random(in: -15...15)
                }
            }
            .onTapGesture { onTap() }
    }
}

// MARK: - Stone View

private struct StoneView: View {
    let stone: GardenView.Stone
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "sparkle")
                .font(.system(size: 8))
                .foregroundColor(Color(hex: "FFEB3B").opacity(0.4))

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "6B6B6B"), Color(hex: "4A4A4A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 16)
        }
        .position(stone.position)
        .onTapGesture { onTap() }
    }
}

// MARK: - CGFloat Clamp

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
