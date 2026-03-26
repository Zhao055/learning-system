import SwiftUI

struct GrowthTreeView: View {
    @StateObject private var vm = GrowthTreeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tree visualization
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: ZhiyaTheme.cornerRadiusLG)
                        .fill(
                            LinearGradient(
                                colors: [ZhiyaTheme.lightGreenBg, ZhiyaTheme.cream],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 300)

                    VStack(spacing: 0) {
                        // Crown / Leaves
                        treeCanopy

                        // Trunk
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [ZhiyaTheme.trunkBrown, ZhiyaTheme.trunkBrownDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(vm.tree.trunkThickness) * 8, height: 60)

                        // Roots
                        Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                            .font(.system(size: 20))
                            .foregroundColor(ZhiyaTheme.trunkBrown.opacity(0.5))
                    }
                }
                .padding(.horizontal)

                // Stage info
                ZhiyaCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.treeStage)
                                .font(ZhiyaTheme.heading())
                                .foregroundColor(ZhiyaTheme.darkBrown)
                            Text("\(vm.totalLeaves)片叶子 · \(vm.fullLeaves)片完全展开")
                                .font(ZhiyaTheme.caption())
                                .foregroundColor(ZhiyaTheme.lightBrown)
                        }
                        Spacer()
                        ZhiyaMascotView(emotion: .happy, size: 36)
                    }
                }
                .padding(.horizontal)

                // Four dimensions
                VStack(spacing: 12) {
                    Text("四维成长")
                        .font(ZhiyaTheme.heading(18))
                        .foregroundColor(ZhiyaTheme.darkBrown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ForEach(vm.tree.branches) { branch in
                        ZhiyaCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: branch.dimension.icon)
                                        .foregroundColor(branch.dimension.color)
                                    Text(branch.dimension.label)
                                        .font(ZhiyaTheme.label())
                                        .foregroundColor(ZhiyaTheme.darkBrown)
                                    Spacer()
                                    Text("\(branch.leafCount)片叶子")
                                        .font(ZhiyaTheme.caption())
                                        .foregroundColor(ZhiyaTheme.lightBrown)
                                }
                                StatBarView(label: "", value: branch.length, color: branch.dimension.color)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Growth Stories
                if !vm.growthStories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("成长故事")
                            .font(ZhiyaTheme.heading(18))
                            .foregroundColor(ZhiyaTheme.darkBrown)
                            .padding(.horizontal)

                        ForEach(vm.growthStories) { story in
                            ZhiyaCard {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: story.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(ZhiyaTheme.leafGreen)
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(story.title)
                                            .font(ZhiyaTheme.label())
                                            .foregroundColor(ZhiyaTheme.darkBrown)
                                        Text(story.content)
                                            .font(ZhiyaTheme.body(14))
                                            .foregroundColor(ZhiyaTheme.lightBrown)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Milestones (flowers)
                if !vm.tree.flowers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("里程碑")
                            .font(ZhiyaTheme.heading(18))
                            .foregroundColor(ZhiyaTheme.darkBrown)
                            .padding(.horizontal)

                        ForEach(vm.tree.flowers) { flower in
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(ZhiyaTheme.goldenAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flower.title)
                                        .font(ZhiyaTheme.label())
                                        .foregroundColor(ZhiyaTheme.darkBrown)
                                    Text(flower.bloomDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(ZhiyaTheme.caption(11))
                                        .foregroundColor(ZhiyaTheme.lightBrown)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .navigationTitle("成长之树")
        .onAppear { vm.load() }
    }

    private var treeCanopy: some View {
        let leafCount = vm.tree.leaves.count
        let size: CGFloat = min(200, CGFloat(60 + leafCount * 5))

        return ZStack {
            // Base canopy
            ForEach(0..<3, id: \.self) { i in
                Ellipse()
                    .fill(ZhiyaTheme.leafGreen.opacity(0.6 + Double(i) * 0.15))
                    .frame(width: size - CGFloat(i) * 20, height: size * 0.7 - CGFloat(i) * 15)
                    .offset(x: CGFloat(i - 1) * 15, y: CGFloat(i) * -10)
            }

            // Leaf count
            Text("\(leafCount)")
                .font(ZhiyaTheme.title(28))
                .foregroundColor(.white)
        }
        .frame(height: size * 0.7)
    }
}

