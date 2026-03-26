# 知芽 iOS App — CLAUDE.md

## Build & Run
- Open `ZhiyaApp.xcodeproj` in Xcode
- Target: iPhone (iOS 17+)
- No external dependencies (pure SwiftUI + Foundation)

## Architecture
- **MVVM** with coordinator pattern
- **Synapse Hybrid Mode**: SynapseAPI (server) + AIService (direct MiniMax fallback)
- NetworkMonitor (NWPathMonitor) auto-switches between modes

## SwiftUI Layout Rules (HARD CONSTRAINTS)
1. **NEVER** use `fixedSize` + `Spacer` in `ScrollView > LazyVStack` for width control — unreliable
2. **NEVER** use `layoutPriority` for width constraints — fragile and context-dependent
3. **ALWAYS** pass `availableWidth: CGFloat` to chat bubbles; compute once via `GeometryReader` at parent
4. **ALWAYS** use `.frame(maxWidth: availableWidth * factor)` for bubble width
5. **NEVER** hardcode coordinates (e.g. `x: 190, y: 300`) — use `GeometryReader` relative positioning
6. **ALWAYS** use `TabView(.page)` for swipe navigation — never manual `DragGesture` + offset

## File Organization
```
ZhiyaApp/
├── ZhiyaApp.swift          # App entry
├── Design/                  # Theme, components, images
├── Extensions/              # Color+Zhiya
├── Models/                  # Data structures (Codable)
├── Services/                # Business logic (singletons)
├── ViewModels/              # UI state (ObservableObject)
├── Views/                   # SwiftUI views
│   ├── Chat/                # Chat bubble system
│   ├── Companion/           # Main companion screen
│   ├── Components/          # Reusable UI parts
│   ├── Garden/              # Growth garden
│   ├── Growth/              # Growth tree, celebrations
│   ├── Onboarding/          # First-run experience
│   └── Settings/            # Settings page
├── Resources/               # Images + QuestionBanks JSON
└── docs/                    # Design docs, logbook, test cases
```

## PDCA Discipline
- Every Phase must compile and run on device before proceeding
- Log test results in LOGBOOK.md
- Never write > 5 files without device verification
