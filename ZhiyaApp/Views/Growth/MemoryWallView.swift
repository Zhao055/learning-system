import SwiftUI

struct MemoryWallView: View {
    @State private var memories: [GrowthMemory] = []

    var body: some View {
        Group {
            if memories.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "成长印记",
                    message: "你的学习里程碑和关键时刻会记录在这里。"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(memories) { memory in
                            MemoryCard(memory: memory)
                        }
                    }
                    .padding(ZhiyaTheme.spacingMD)
                }
            }
        }
        .background(ZhiyaTheme.cream.ignoresSafeArea())
        .navigationTitle("成长印记")
        .onAppear {
            memories = MemoryService.shared.getMemories()
        }
    }
}

private struct MemoryCard: View {
    let memory: GrowthMemory

    var body: some View {
        ZhiyaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconForType(memory.type))
                        .foregroundColor(colorForType(memory.type))
                    Text(memory.title)
                        .font(ZhiyaTheme.label())
                        .foregroundColor(ZhiyaTheme.darkBrown)
                    Spacer()
                    Text(memory.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(ZhiyaTheme.caption(11))
                        .foregroundColor(ZhiyaTheme.lightBrown)
                }
                Text(memory.content)
                    .font(ZhiyaTheme.body(14))
                    .foregroundColor(ZhiyaTheme.lightBrown)
            }
        }
    }

    private func iconForType(_ type: MemoryType) -> String {
        switch type {
        case .academicBreakthrough: return "star.fill"
        case .emotionalMoment: return "heart.fill"
        case .lifeDiscovery: return "sparkles"
        case .milestone: return "flag.fill"
        case .dream: return "cloud.fill"
        case .struggle: return "wind"
        case .sharedJoy: return "hands.sparkles.fill"
        }
    }

    private func colorForType(_ type: MemoryType) -> Color {
        switch type {
        case .academicBreakthrough: return ZhiyaTheme.wisdom
        case .emotionalMoment: return ZhiyaTheme.empathy
        case .lifeDiscovery: return ZhiyaTheme.passion
        case .milestone: return ZhiyaTheme.goldenAmber
        case .dream: return ZhiyaTheme.softTeal
        case .struggle: return ZhiyaTheme.lightBrown
        case .sharedJoy: return ZhiyaTheme.integrity
        }
    }
}
